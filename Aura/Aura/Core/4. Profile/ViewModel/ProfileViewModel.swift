//
//  ProfileViewModel.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import Foundation
import Combine

enum ProfileRoutes: Hashable {
    case addProfileInfo
}

@MainActor
final class ProfileViewModel: ObservableObject, AlertPresentable {
    @Published var profileRoutes: [ProfileRoutes] = []

    @Published private(set) var user: UserModel?
    @Published private(set) var dailyTip: DailyContentModel?
    @Published private(set) var personalityState = LoadState.loading
    @Published private(set) var tipState = LoadState.loading
    @Published private(set) var profileForm: ProfileFormViewModel?
    @Published private(set) var isSavingProfile = false
    
    @Published private var alertPresented = false
    @Published var alertMessage = ""
    @Published var showSettings = false
    @Published private var signOutAlertPresented = false
    @Published private var deleteAccountAlertPresented = false
    @Published private var deleteAccountErrorPresented = false
    @Published private(set) var isDeletingAccount = false

    @Published private var personalityResult: PersonalityResultModel?
    private var personalityHistoryID: UUID?
    private var tipRequestID: UUID?
    private var currentUserId: UUID?
    private var openProfileFormAfterSettings = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    var showAlert: Bool {
        get { alertPresented }
        set {
            guard alertPresented != newValue else { return }
            alertPresented = newValue
        }
    }

    var showSignOutAlert: Bool {
        get { signOutAlertPresented }
        set {
            guard signOutAlertPresented != newValue else { return }
            signOutAlertPresented = newValue
        }
    }

    var showDeleteAccountAlert: Bool {
        get { deleteAccountAlertPresented }
        set {
            guard deleteAccountAlertPresented != newValue else { return }
            deleteAccountAlertPresented = newValue
        }
    }

    var showDeleteAccountError: Bool {
        get { deleteAccountErrorPresented }
        set {
            guard deleteAccountErrorPresented != newValue else { return }
            deleteAccountErrorPresented = newValue
        }
    }

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

        setupSubscriptions()
    }

    var hasPersonalityTests: Bool {
        personalityResult != nil
    }

    var profileDisplay: ProfileDisplayModel {
        guard let personalityResult else { return .placeholder }
        return ProfileDisplayModel.make(personalityResult: personalityResult, dailyTip: dailyTip)
    }

    var needsAIConsent: Bool {
        guard hasPersonalityTests, let user else { return false }
        return !user.allowsAIAnalysis
    }

    private func setupSubscriptions() {
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
            }
            .store(in: &cancellables)

        contentService.historyCells
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await loadPersonality() }
            }
            .store(in: &cancellables)

        contentService.historyState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, !hasPersonalityTests, state != .loaded else { return }
                personalityState = state
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ authState: AuthState) {
        switch authState {
            case .signedIn(let user):
                handleUser(user)
            case .signedOut:
                guard currentUserId != nil else { return }
                currentUserId = nil
                tipRequestID = nil
                dailyTip = nil
                cancellables.removeAll()
        }
    }

    private func handleUser(_ user: UserModel) {
        let previousUser = self.user
        self.user = user

        guard currentUserId == user.id else {
            currentUserId = user.id
            Task { await loadDailyTip() }
            return
        }

        if previousUser?.allowsAIAnalysis == false && user.allowsAIAnalysis {
            Task { await loadDailyTip() }
        }
    }

    func refresh() async {
        guard currentUserId != nil else { return }
        let sessionID = authService.sessionID

        if dailyTip?.isFromToday != true {
            dailyTip = nil
            tipState = .loading
        }

        do {
            try await contentService.fetchHistory()
        } catch {
            guard sessionID == authService.sessionID else { return }
            if !hasPersonalityTests {
                personalityState = .failed(error.userMessage)
            }
        }

        guard sessionID == authService.sessionID else { return }
        await loadDailyTip()
    }

    func retryPersonality() {
        Task { await refresh() }
    }

    func retryDailyTip() {
        Task { await loadDailyTip() }
    }

    func refreshLocalizedContent() {
        tipRequestID = nil
        dailyTip = nil
        tipState = .loading
        retryDailyTip()
    }

    private func loadDailyTip() async {
        guard user?.allowsAIAnalysis == true, user?.dateOfBirth != nil else { return }
        if dailyTip?.isFromToday == true { return }
        let sessionID = authService.sessionID
        let requestID = UUID()
        tipRequestID = requestID
        let languageCode = AppLanguage.requestCode

        dailyTip = nil
        tipState = .loading

        func isCurrentRequest() -> Bool {
            requestID == tipRequestID &&
            languageCode == AppLanguage.requestCode &&
            sessionID == authService.sessionID
        }

        do {
            let tip = try await contentService.fetchDailyTip()
            guard isCurrentRequest() else { return }
            guard tip.isFromToday else { throw NetworkError.invalidResponse }
            dailyTip = tip
            tipState = .loaded
        } catch {
            guard isCurrentRequest() else { return }
            if dailyTip?.isFromToday != true {
                dailyTip = nil
                tipState = .failed(error.userMessage)
            }
        }
    }

    private func loadPersonality() async {
        guard currentUserId != nil, contentService.historyState.value == .loaded else { return }
        let sessionID = authService.sessionID

        guard let latest = contentService.historyCells.value.first(where: { $0.kind == .personality }) else {
            clearPersonality()
            return
        }

        guard personalityHistoryID != latest.id else { return }
        personalityHistoryID = latest.id
        if !hasPersonalityTests { personalityState = .loading }

        func isCurrentRequest() -> Bool {
            sessionID == authService.sessionID &&
            personalityHistoryID == latest.id &&
            contentService.historyCells.value.first(where: { $0.kind == .personality })?.id == latest.id
        }

        do {
            let details = try await contentService.fetchHistoryDetails(id: latest.id)
            guard isCurrentRequest() else { return }
            guard let result = details.personalityResult else {
                clearPersonality()
                return
            }
            personalityResult = result
            personalityState = .loaded
        } catch {
            guard isCurrentRequest() else { return }
            personalityHistoryID = nil
            if !hasPersonalityTests {
                personalityState = .failed(error.userMessage)
            }
        }
    }

    func showAddProfileInfo() {
        guard let user else { return }

        profileForm = ProfileFormViewModel(user: user)
        profileRoutes.append(.addProfileInfo)
    }

    func editProfileAfterSettings() {
        openProfileFormAfterSettings = true
        showSettings = false
    }

    func openProfileFormIfNeeded() {
        guard openProfileFormAfterSettings else { return }
        openProfileFormAfterSettings = false
        showAddProfileInfo()
    }

    func saveProfileInfo() {
        guard let profileForm, !isSavingProfile else { return }

        let request: ProfileInfoModel
        do {
            request = try profileForm.profileInfoRequest()
        } catch {
            profileForm.presentAlert(error.userMessage)
            return
        }

        isSavingProfile = true

        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                try await authService.updateProfileInfo(request)
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                profileRoutes = []
                try await Task.sleep(for: .milliseconds(50))
                guard sessionID == authService.sessionID else { return }
                self.profileForm = nil
            } catch {
                guard sessionID == authService.sessionID else { return }
                profileForm.presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isSavingProfile = false
        }
    }

    func openSettings() {
        showSettings = true
    }

    func requestSignOut() {
        showSignOutAlert = true
    }

    func requestAccountDeletion() {
        showDeleteAccountAlert = true
    }

    func signOut() {
        Task {
            do {
                try await authService.signOut()
                showSettings = false
                showAlert = false
            } catch {
                presentAlert(error.userMessage)
            }
        }
    }

    func deleteAccount() {
        guard !isDeletingAccount else { return }

        isDeletingAccount = true

        Task {
            do {
                try await authService.deleteAccount()
                showSettings = false
                showAlert = false
            } catch {
                alertMessage = error.userMessage
                showDeleteAccountError = true
            }

            isDeletingAccount = false
        }
    }

    private func clearPersonality() {
        personalityHistoryID = nil
        personalityResult = nil
        personalityState = .loaded
    }
}
