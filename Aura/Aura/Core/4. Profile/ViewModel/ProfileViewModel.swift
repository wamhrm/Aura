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
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var hasPersonalityTests = false
    @Published var showSettings = false
    @Published var showSignOutAlert = false
    @Published var showDeleteAccountAlert = false
    @Published var showDeleteAccountError = false
    @Published private(set) var isDeletingAccount = false

    private var personalityResult: PersonalityResultModel?
    private var currentUserId: UUID?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let storage: any LocalStorageProtocol

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.authService = authService
        self.contentService = contentService
        self.storage = storage

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

        contentService.historyDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, let userId = currentUserId else { return }
                Task { await loadPersonality(for: userId) }
            }
            .store(in: &cancellables)

        contentService.refreshRequested
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await refresh() }
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

            if let cached = storage.load(StorageKeys.personality, for: user.id) {
                applyPersonality(result: cached.result)
            }

            let cachedTip = storage.load(StorageKeys.dailyTip, for: user.id)
            dailyTip = cachedTip?.isFromToday == true ? cachedTip : nil
            updateProfileDisplay()

            Task { await refresh() }
            return
        }

        if previousUser?.allowsAIAnalysis == false && user.allowsAIAnalysis {
            Task { await loadDailyTip(for: user.id) }
        }
    }

    func refresh() async {
        guard let user, let userId = currentUserId else { return }

        async let personality: Void = loadPersonality(for: userId)

        if user.allowsAIAnalysis {
            await loadDailyTip(for: userId)
        }

        await personality
    }

    // The only retry button on the locked screen, so it brings back the tip hidden behind the blur as well
    func retryPersonality() {
        Task { await refresh() }
    }

    func retryDailyTip() {
        guard let userId = currentUserId else { return }
        Task { await loadDailyTip(for: userId) }
    }

    private func loadDailyTip(for userId: UUID) async {
        if dailyTip == nil {
            tipState = .loading
        }

        do {
            let tip = try await contentService.fetchDailyTip(for: userId)
            guard currentUserId == userId else { return }

            dailyTip = tip
            tipState = .loaded
        } catch {
            guard currentUserId == userId, !error.isCancellation else { return }

            // Yesterday's tip must not stay on screen as today's
            if dailyTip?.isFromToday != true {
                dailyTip = nil
                tipState = .failed(error.userMessage)
            }
        }

        updateProfileDisplay()
    }

    private func loadPersonality(for userId: UUID) async {
        if !hasPersonalityTests {
            personalityState = .loading
        }

        do {
            let history = try await contentService.fetchHistory()
            guard currentUserId == userId else { return }

            storage.save(history, for: StorageKeys.history, userId: userId)

            guard let latest = history.first(where: { $0.kind == .personality }) else {
                return clearPersonality(for: userId)
            }

            if let cached = storage.load(StorageKeys.personality, for: userId), cached.historyId == latest.id {
                return applyPersonality(result: cached.result)
            }

            let historyDetails = try await contentService.fetchHistoryDetails(id: latest.id)
            guard currentUserId == userId else { return }

            guard let result = historyDetails.personalityResult else {
                return clearPersonality(for: userId)
            }

            applyPersonality(result: result)
            storage.save(StoredPersonality(historyId: latest.id, result: result),
                         for: StorageKeys.personality,
                         userId: userId)
        } catch {
            guard currentUserId == userId, !error.isCancellation else { return }

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
        showSettings = false
        showAlert = false
        authService.signOut()
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

    private func clearPersonality(for userId: UUID) {
        hasPersonalityTests = false
        personalityResult = nil
        personalityState = .loaded
        storage.delete(StorageKeys.personality, for: userId)
        updateProfileDisplay()
    }
}
