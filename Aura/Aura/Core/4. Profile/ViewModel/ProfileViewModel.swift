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

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""

    @Published private(set) var authState = AuthState.signedOut
    @Published private(set) var profileDisplay: ProfileDisplayModel?
    @Published private(set) var dailyTip: DailyContentModel?
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false
    @Published var isServerWakingUp = false
    @Published private(set) var hasPersonalityTests = false
    @Published private(set) var isSignedOut = false
    @Published var showSettings = false
    @Published var showSignOutAlert = false
    @Published var showDeleteAccountAlert = false
    @Published var showDeleteAccountError = false
    @Published private(set) var isDeletingAccount = false
    @Published var showSignIn = false
    @Published var showCreateAccount = false

    private var personalityResult: PersonalityResultModel?
    private var compatibilityHistory: [HistoryCellModel] = []

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let storage: any LocalStorageProtocol
    private let transitionDuration = 0.25
    private let maxSignInWait = 3.0

    private var signInAttempt = UUID()
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

                compatibilityHistory = storage.load(StorageKeys.history, for: user.id) ?? []

                if user.hasCompletedProfileInfo {
                    dailyTip = storage.load(StorageKeys.dailyTip, for: user.id)
                } else {
                    dailyTip = nil
                    storage.delete(StorageKeys.dailyTip, for: user.id)
                }

                updateProfileDisplay()
                isSignedOut = false

                if isLoading {
                    let attempt = UUID()
                    signInAttempt = attempt

                    Task {
                        await refreshContent(for: user)
                        finishSignIn(user, attempt: attempt)
                    }

                    Task {
                        try? await Task.sleep(for: .seconds(maxSignInWait))
                        finishSignIn(user, attempt: attempt)
                    }
                } else {
                    withAnimation(.easeInOut(duration: transitionDuration)) {
                        authState = .signedIn(user)
                    }

                    Task { await refreshContent(for: user) }
                }
            case .signedOut:
                withAnimation(.easeInOut(duration: transitionDuration)) { authState = .signedOut }

                Task {
                    try? await Task.sleep(for: .seconds(transitionDuration))
                    hasPersonalityTests = false
                    personalityResult = nil
                    dailyTip = nil
                    profileDisplay = nil
                    compatibilityHistory = []
                    isSignedOut = true
                }
        }
    }
    
    private func finishSignIn(_ user: UserModel, attempt: UUID) {
        guard attempt == signInAttempt, isLoading else { return }

        signInAttempt = UUID()

        withAnimation(.easeInOut(duration: transitionDuration)) {
            authState = .signedIn(user)
        }

        Task {
            try? await Task.sleep(for: .seconds(transitionDuration))
            isLoading = false
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
            compatibilityHistory = history
            storage.save(history, for: StorageKeys.history, userId: userId)
            updateProfileDisplay()

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

    func createAccount() {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = validateCreateAccount(name: name, email: email, password: password) {
            presentAlert(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            await withServerWakeUpIndicator(after: .seconds(12)) {
                do {
                    try await authService.createAccount(name: name, email: email, password: password)
                } catch {
                    presentAlert(error.localizedDescription)
                    isLoading = false
                }
            }
        }
    }

    func signIn() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = validateSignIn(email: email, password: password) {
            presentAlert(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            await withServerWakeUpIndicator(after: .seconds(12)) {
                do {
                    try await authService.signIn(email: email, password: password)
                } catch {
                    presentAlert(error.localizedDescription)
                    isLoading = false
                }
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

    func clearTextFields() {
        name = ""
        email = ""
        password = ""
    }
    
    func dismissSignInCreateViews() {
        showSignIn = false
        showCreateAccount = false
    }

    func toggleSignInCreateView() {
        showSignIn.toggle()
        showCreateAccount.toggle()
    }

    private func updateProfileDisplay() {
        profileDisplay = ProfileDisplayModel.make(personalityResult: personalityResult,
                                                  dailyTip: dailyTip,
                                                  history: compatibilityHistory)
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

    private func validateSignIn(email: String, password: String) -> String? {
        guard !email.isEmpty, !password.isEmpty else {
            return "Заполните почту и пароль"
        }
        if let error = emailError(email) { return error }
        if let error = passwordError(password) { return error }
        return nil
    }

    private func validateCreateAccount(name: String, email: String, password: String) -> String? {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            return "Заполните имя, почту и пароль"
        }
        if let error = nameError(name) { return error }
        if let error = emailError(email) { return error }
        if let error = passwordError(password) { return error }
        return nil
    }

    private func nameError(_ name: String) -> String? {
        if name.isEmpty {
            return "Укажите имя"
        }
        if name.count < AuthInput.minNameLength {
            return "Имя должно содержать минимум \(AuthInput.minNameLength) символа"
        }
        return nil
    }

    private func emailError(_ email: String) -> String? {
        if email.isEmpty {
            return "Укажите почту"
        }
        if !Self.isValidEmail(email) {
            return "Укажите корректный e-mail"
        }
        return nil
    }

    private func passwordError(_ password: String) -> String? {
        if password.isEmpty {
            return "Укажите пароль"
        }
        if password.count < AuthInput.minPasswordLength {
            return "Пароль должен быть не короче \(AuthInput.minPasswordLength) символов"
        }
        return nil
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let local = parts[0]
        let domain = parts[1]
        return !local.isEmpty && !domain.isEmpty
    }
}

private enum AuthInput {
    static let minPasswordLength = 6
    static let minNameLength = 2
}
