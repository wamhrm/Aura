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
    @Published private(set) var profileDisplay: ProfileDisplayModel?
    @Published private(set) var dailyTip: DailyContentModel?
    @Published private(set) var personalityState = LoadState.loading
    @Published private(set) var tipState = LoadState.loading
    @Published private(set) var profileForm: ProfileFormViewModel?
    @Published private(set) var isSavingProfile = false
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var hasPersonalityTests = false
    @Published var showSettings = false
    @Published var showSignOutAlert = false
    @Published var showDeleteAccountAlert = false
    @Published var showDeleteAccountError = false
    @Published private(set) var isDeletingAccount = false

    private var personalityResult: PersonalityResultModel?
    private var loadedPersonalityId: UUID?
    private var currentUserId: UUID?
    private var savingStarted: ContinuousClock.Instant?
    private var openProfileFormAfterSettings = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

        setupSubscriptions()
    }

    var profileDisplayHandler: ProfileDisplayModel {
        guard hasPersonalityTests, let profileDisplay else { return .placeholder }
        return profileDisplay
    }

    var needsAIConsent: Bool {
        guard hasPersonalityTests, let user else { return false }
        return !user.allowsAIAnalysis
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
            }
            .store(in: &cancellables)

        contentService.historyCells
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cells in
                guard let self else { return }
                Task { await loadPersonality(from: cells) }
            }
            .store(in: &cancellables)

        contentService.dailyTip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tip in
                guard let self else { return }
                dailyTip = tip
                if tip != nil { tipState = .loaded }
                updateProfileDisplay()
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
                cancellables.removeAll()
        }
    }

    private func handleUser(_ user: UserModel) {
        let previousUser = self.user

        self.user = user

        guard currentUserId == user.id else {
            currentUserId = user.id
            Task { await refresh() }
            return
        }

        if previousUser?.allowsAIAnalysis == false && user.allowsAIAnalysis {
            Task { await loadDailyTip() }
        }
    }

    func refresh() async {
        guard currentUserId != nil else { return }

        if dailyTip?.isFromToday != true {
            dailyTip = nil
            tipState = .loading
            updateProfileDisplay()
        }

        do {
            let history = try await contentService.fetchHistory()
            await loadPersonality(from: history)
        } catch {
            if !hasPersonalityTests {
                personalityState = .failed(error.userMessage)
            }
        }

        await loadDailyTip()
    }

    func retryPersonality() {
        Task { await refresh() }
    }

    func retryDailyTip() {
        Task { await loadDailyTip() }
    }

    private func loadDailyTip() async {
        guard user?.allowsAIAnalysis == true, user?.dateOfBirth != nil else { return }
        if dailyTip?.isFromToday == true { return }

        if dailyTip == nil {
            tipState = .loading
        }

        do {
            dailyTip = try await contentService.fetchDailyTip()
            tipState = .loaded
            updateProfileDisplay()
        } catch {
            if dailyTip?.isFromToday != true {
                dailyTip = nil
                tipState = .failed(error.userMessage)
                updateProfileDisplay()
            }
        }
    }

    private func loadPersonality(from history: [HistoryCellModel]) async {
        guard currentUserId != nil else { return }

        guard let latest = history.first(where: { $0.kind == .personality }) else {
            clearPersonality()
            return
        }

        if loadedPersonalityId == latest.id, personalityResult != nil {
            return
        }

        if !hasPersonalityTests {
            personalityState = .loading
        }

        do {
            let historyDetails = try await contentService.fetchHistoryDetails(id: latest.id)
            guard let result = historyDetails.personalityResult else {
                clearPersonality()
                return
            }

            loadedPersonalityId = latest.id
            applyPersonality(result: result)
        } catch {
            if !hasPersonalityTests {
                personalityState = .failed(error.userMessage)
            }
        }
    }

    func showAddProfileInfo() {
        guard let user else { return }

        profileForm = ProfileFormViewModel(authService: authService, user: user)
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

    func noteProfileSaving(_ isSaving: Bool) {
        if isSaving {
            if savingStarted == nil { savingStarted = .now }
        } else {
            savingStarted = nil
        }
        isSavingProfile = isSaving
    }

    func finishProfileEditing() async {
        if let savingStarted {
            let deadline = savingStarted.advanced(by: .seconds(CoveredTransition.appearSeconds))
            try? await Task.sleep(until: deadline, clock: .continuous)
        }

        profileRoutes = []
        try? await Task.sleep(for: CoveredTransition.settleDuration)
        isSavingProfile = false
        savingStarted = nil
        profileForm = nil
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

    private func updateProfileDisplay() {
        profileDisplay = ProfileDisplayModel.make(personalityResult: personalityResult,
                                                  dailyTip: dailyTip)
    }

    private func applyPersonality(result: PersonalityResultModel) {
        personalityResult = result
        hasPersonalityTests = true
        personalityState = .loaded
        updateProfileDisplay()
    }

    private func clearPersonality() {
        loadedPersonalityId = nil
        hasPersonalityTests = false
        personalityResult = nil
        personalityState = .loaded
        updateProfileDisplay()
    }
}
