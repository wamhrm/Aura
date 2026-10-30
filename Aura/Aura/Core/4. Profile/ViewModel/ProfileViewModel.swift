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
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var hasPersonalityTests = false
    @Published var showSettings = false
    @Published var showSignOutAlert = false
    @Published var showDeleteAccountAlert = false
    @Published var showDeleteAccountError = false
    @Published private(set) var isDeletingAccount = false

    private var personalityResult: PersonalityResultModel?

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
        profileDisplay ?? .placeholder
    }

    var needsAIConsent: Bool {
        guard hasPersonalityTests, let user else { return false }
        return !user.allowsAIAnalysis
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, case .signedIn(let user) = $0 else { return }
                handleSignIn(user)
            }
            .store(in: &cancellables)

        contentService.historyDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, let user else { return }
                Task { await loadPersonality(for: user.id) }
            }
            .store(in: &cancellables)
    }

    private func handleSignIn(_ user: UserModel) {
        if let cached = storage.load(StorageKeys.personality, for: user.id) {
            applyPersonality(result: cached.result)
        }

        dailyTip = storage.load(StorageKeys.dailyTip, for: user.id)
        updateProfileDisplay()
        self.user = user

        Task { await refreshContent(for: user) }
    }
    
    private func refreshContent(for user: UserModel) async {
        async let personality: Void = loadPersonality(for: user.id, showErrorOnFailure: false)

        if user.allowsAIAnalysis {
            await loadDailyTip(for: user.id)
        }

        await personality
    }

    private func loadDailyTip(for userId: UUID) async {
        guard let tip = try? await contentService.fetchDailyTip(for: userId) else { return }

        dailyTip = tip
        updateProfileDisplay()
    }

    private func loadPersonality(for userId: UUID, showErrorOnFailure: Bool = true) async {
        do {
            let history = try await contentService.fetchHistory()
            storage.save(history, for: StorageKeys.history, userId: userId)

            guard let latest = history.first(where: { $0.kind == .personality }) else {
                return clearPersonality(for: userId)
            }

            if let cached = storage.load(StorageKeys.personality, for: userId), cached.historyId == latest.id {
                return applyPersonality(result: cached.result)
            }

            let historyDetails = try await contentService.fetchHistoryDetails(id: latest.id)
            guard let result = historyDetails.personalityResult else {
                return clearPersonality(for: userId)
            }

            applyPersonality(result: result)
            storage.save(StoredPersonality(historyId: latest.id, result: result),
                         for: StorageKeys.personality,
                         userId: userId)
        } catch {
            if showErrorOnFailure {
                presentAlert(error.userMessage)
            }
        }
    }

    func showAddProfileInfo() {
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
        updateProfileDisplay()
    }

    private func clearPersonality(for userId: UUID) {
        hasPersonalityTests = false
        personalityResult = nil
        storage.delete(StorageKeys.personality, for: userId)
        updateProfileDisplay()
    }
}
