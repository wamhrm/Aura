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
    case completeProfile, settings
}

private enum AuthInput {
    static let minPasswordLength = 6
    static let minNameLength = 2
    static let authActionDelay = Duration.seconds(1)
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""

    @Published var profileRoutes: [ProfileRoutes] = []
    @Published private(set) var authState = AuthState.signedOut
    @Published private(set) var isLoading = false

    @Published var showSettings = false
    @Published var showError = false
    @Published private(set) var errorMessage = ""

    private let authService: any AuthServiceProtocol
    private let personalityService: any PersonalityServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()

    var isProfileCompleted: Bool {
        return false
    }

    init(authService: any AuthServiceProtocol,
         personalityService: any PersonalityServiceProtocol) {
        self.authService = authService
        self.personalityService = personalityService

        setupSubscriptions()
    }

    deinit {
        cancellables.removeAll()
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] authState in
                self?.authState = authState
            }
            .store(in: &cancellables)
    }

    func createAccount() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = validateCreateAccount(name: trimmedName, email: trimmedEmail, password: password) {
            showError(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await Task.sleep(for: AuthInput.authActionDelay)
                try await authService.createAccount(name: trimmedName, email: trimmedEmail, password: password)

                profileRoutes = []
                clearFields()
            } catch {
                showError(error.localizedDescription)
            }

            isLoading = false
        }
    }

    func signIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = validateSignIn(email: trimmedEmail, password: password) {
            showError(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await Task.sleep(for: AuthInput.authActionDelay)
                try await authService.signIn(email: trimmedEmail, password: password)

                profileRoutes = []
                clearFields()
            } catch {
                showError(error.localizedDescription)
            }

            isLoading = false
        }
    }

    func signOut() {
        guard !isLoading else { return }

        isLoading = true
        
        Task {
            try? await Task.sleep(for: AuthInput.authActionDelay)
            authService.signOut()
            
            profileRoutes = []
            showSettings = false
            isLoading = false
        }
    }

    private func clearFields() {
        name = ""
        email = ""
        password = ""
    }

    private func showError(_ message: String) {
        showError = true
        errorMessage = message
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
