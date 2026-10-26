//
//  ProfileViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import Combine
import SwiftUI

enum ProfileRoutes: Hashable {
    case addProfileInfo
}

@MainActor
final class ProfileViewModel: ObservableObject, LoadingStatePresentable {
    @Published var profileRoutes: [ProfileRoutes] = []

    @Published private(set) var authState = AuthState.signedOut
    @Published private(set) var profileDisplay: ProfileDisplayModel?
    @Published private(set) var dailyTip: DailyContentModel?
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var hasPersonalityTests = false
    @Published private(set) var isSignedOut = false
    @Published var showSettings = false
    @Published var showSignOutAlert = false
    @Published var showDeleteAccountAlert = false
    @Published var showDeleteAccountError = false
    @Published private(set) var isDeletingAccount = false

    private var personalityResult: PersonalityResultModel?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let storage: any LocalStorageProtocol
    private let transitionDuration = 0.25

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.authService = authService
        self.contentService = contentService
        self.storage = storage

        setupSubscriptions()
    }

    var needsAIConsent: Bool {
        guard hasPersonalityTests, case .signedIn(let user) = authState else { return false }
        return !user.allowsAIAnalysis
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.handleAuthState($0)
            }
            .store(in: &cancellables)

        contentService.historyDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, case .signedIn(let user) = authState else { return }
                Task { await self.loadPersonality(for: user.id, ignoreCache: true) }
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ state: AuthState) {
        switch state {
            case .signedIn(let user):
                if let cached = storage.load(StorageKeys.personality, for: user.id) {
                    applyPersonality(result: cached.result)
                } else {
                    hasPersonalityTests = false
                    personalityResult = nil
                }

                if user.hasCompletedProfileInfo {
                    dailyTip = storage.load(StorageKeys.dailyTip, for: user.id)
                } else {
                    dailyTip = nil
                    storage.delete(StorageKeys.dailyTip, for: user.id)
                }

                updateProfileDisplay()
                isSignedOut = false

                withAnimation(.easeInOut(duration: transitionDuration)) {
                    authState = .signedIn(user)
                }

                Task { await refreshContent(for: user) }
            case .signedOut:
                withAnimation(.easeInOut(duration: transitionDuration)) { authState = .signedOut }

                Task {
                    try? await Task.sleep(for: .seconds(transitionDuration))
                    hasPersonalityTests = false
                    personalityResult = nil
                    dailyTip = nil
                    profileDisplay = nil
                    isSignedOut = true
                }
        }
    }
    
    private func refreshContent(for user: UserModel) async {
        async let personality: Void = loadPersonality(for: user.id, ignoreCache: true, showErrorOnFailure: false)

        if user.hasCompletedProfileInfo && user.allowsAIAnalysis {
            await loadDailyTip(for: user.id, showErrorOnFailure: false)
        }

        await personality
    }

    private func loadDailyTip(for userId: UUID, showErrorOnFailure: Bool = true) async {
        do {
            let tip = try await contentService.fetchDailyTip()
            dailyTip = tip
            storage.save(tip, for: StorageKeys.dailyTip, userId: userId)
            updateProfileDisplay()
        } catch {
            if showErrorOnFailure {
                presentAlert(error.localizedDescription)
            }
        }
    }

    private func loadPersonality(for userId: UUID,
                                 ignoreCache: Bool = false,
                                 showErrorOnFailure: Bool = true) async {
        if !ignoreCache, let cached = storage.load(StorageKeys.personality, for: userId) {
            applyPersonality(result: cached.result)
            return
        }

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
                presentAlert(error.localizedDescription)
            }
        }
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
                alertMessage = error.localizedDescription
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
