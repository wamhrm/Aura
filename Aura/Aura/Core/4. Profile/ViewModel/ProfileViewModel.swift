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
final class ProfileViewModel: ObservableObject {
    @Published var profileRoutes: [ProfileRoutes] = []

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var personalityResult: PersonalityResultModel?

    @Published private(set) var authState = AuthState.signedOut
    @Published private(set) var isLoading = false
    @Published private(set) var isServerWakingUp = false
    @Published private(set) var hasPersonalityTests = false
    @Published private(set) var isSignedOut = false
    @Published private(set) var dailyTip: DailyContentModel?
    @Published private(set) var profileDisplay: ProfileDisplayModel?

    @Published var showSettings = false
    @Published var showAlert = false
    @Published private(set) var alertMessage = ""

    private var compatibilityHistory: [HistoryCellModel] = []

    let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

        setupSubscriptions()
    }

    deinit {
        cancellables.removeAll()
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
                if let cached = UserDefaultsHelper.getLocalPersonality(for: user.id) {
                    applyPersonality(result: cached)
                } else {
                    hasPersonalityTests = false
                    personalityResult = nil
                }

                compatibilityHistory = UserDefaultsHelper.getLocalHistory(for: user.id) ?? []

                if user.hasCompletedProfileInfo {
                    dailyTip = UserDefaultsHelper.getLocalDailyTip(for: user.id)
                } else {
                    dailyTip = nil
                    UserDefaultsHelper.deleteLocalDailyTip(for: user.id)
                }

                updateProfileDisplay()
                isSignedOut = false

                if isLoading {
                    Task {
                        if user.hasCompletedProfileInfo {
                            await loadDailyTip(for: user.id, showErrorOnFailure: false)
                        }
                        await loadPersonality(for: user.id, ignoreCache: true)
                        try? await Task.sleep(for: .seconds(1.5))

                        withAnimation(.easeInOut(duration: 0.25)) {
                            authState = .signedIn(user)
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        authState = .signedIn(user)
                    }

                    Task {
                        if user.hasCompletedProfileInfo {
                            await loadDailyTip(for: user.id, showErrorOnFailure: false)
                        }
                        await loadPersonality(for: user.id, ignoreCache: true)
                    }
                }
            case .signedOut:
                withAnimation(.easeInOut(duration: 0.25)) { authState = .signedOut }

                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    hasPersonalityTests = false
                    personalityResult = nil
                    dailyTip = nil
                    profileDisplay = nil
                    compatibilityHistory = []
                    isSignedOut = true
                }
        }
    }

    private func loadDailyTip(for userId: UUID, showErrorOnFailure: Bool = true) async {
        do {
            let tip = try await contentService.fetchDailyTip()
            dailyTip = tip
            UserDefaultsHelper.saveDailyTipLocally(tip, for: userId)
            updateProfileDisplay()
        } catch {
            if showErrorOnFailure {
                showError(error.localizedDescription)
            }
        }
    }

    private func loadPersonality(for userId: UUID, ignoreCache: Bool = false) async {
        if !ignoreCache, let cached = UserDefaultsHelper.getLocalPersonality(for: userId) {
            applyPersonality(result: cached)
            return
        }

        do {
            let history = try await contentService.fetchHistory()
            compatibilityHistory = history
            UserDefaultsHelper.saveHistoryLocally(history, for: userId)
            updateProfileDisplay()

            guard let latest = history.first(where: { $0.kind == .personality }) else {
                return clearPersonality(for: userId)
            }

            let historyDetails = try await contentService.fetchHistoryDetails(id: latest.id)
            guard let result = historyDetails.personalityResult else {
                return clearPersonality(for: userId)
            }

            applyPersonality(result: result)
            UserDefaultsHelper.savePersonalityLocally(result, for: userId)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func createAccount() {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = validateCreateAccount(name: name, email: email, password: password) {
            showError(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            let loadedTask = Task {
                try await Task.sleep(for: .seconds(8))

                if !Task.isCancelled {
                    withAnimation { isServerWakingUp = true }
                }
            }

            defer { loadedTask.cancel() }

            do {
                try await authService.createAccount(name: name, email: email, password: password)
            } catch {
                showError(error.localizedDescription)
            }

            withAnimation { isServerWakingUp = false }
            try? await Task.sleep(for: .seconds(2))
            isLoading = false
        }
    }

    func signIn() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = validateSignIn(email: email, password: password) {
            showError(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            let loadedTask = Task {
                try await Task.sleep(for: .seconds(8))

                if !Task.isCancelled {
                    withAnimation { isServerWakingUp = true }
                }
            }

            defer { loadedTask.cancel() }

            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                showError(error.localizedDescription)
            }

            withAnimation { isServerWakingUp = false }
            try? await Task.sleep(for: .seconds(2))
            isLoading = false
        }
    }

    func signOut() {
        showSettings = false
        authService.signOut()
    }

    func clearTextFields() {
        name = ""
        email = ""
        password = ""
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

    private func showError(_ message: String) {
        showAlert = true
        alertMessage = message
    }

    private func clearPersonality(for userId: UUID) {
        hasPersonalityTests = false
        personalityResult = nil
        UserDefaultsHelper.deleteLocalPersonality(for: userId)
        updateProfileDisplay()
    }

    private func validateSignIn(email: String, password: String) -> String? {
        if email.isEmpty, password.isEmpty {
            return "Заполните почту и пароль"
        }
        if email.isEmpty {
            return "Укажите почту"
        }
        if password.isEmpty {
            return "Укажите пароль"
        }
        if !Self.isValidEmail(email) {
            return "Укажите корректный e-mail"
        }
        if password.count < AuthInput.minPasswordLength {
            return "Пароль должен быть не короче \(AuthInput.minPasswordLength) символов"
        }
        return nil
    }

    private func validateCreateAccount(name: String, email: String, password: String) -> String? {
        if name.isEmpty, email.isEmpty, password.isEmpty {
            return "Заполните имя, почту и пароль"
        }
        if name.isEmpty {
            return "Укажите имя"
        }
        if email.isEmpty {
            return "Укажите почту"
        }
        if password.isEmpty {
            return "Укажите пароль"
        }
        if name.count < AuthInput.minNameLength {
            return "Имя должно содержать минимум \(AuthInput.minNameLength) символа"
        }
        if !Self.isValidEmail(email) {
            return "Укажите корректный e-mail"
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
