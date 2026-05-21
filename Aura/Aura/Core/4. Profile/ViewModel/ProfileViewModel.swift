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
    @Published private(set) var hasPersonalityTests = false

    @Published var showSettings = false
    @Published var showError = false
    @Published private(set) var errorMessage = ""

    private let authService: any AuthServiceProtocol
    private let psychologyService: any PsychologyServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    
    var personalityOverview: String {
        personalityResult?.overview.description ?? "Интуитивный креатор. Глубокий интроверт с мощной интуицией, который ищет настоящую связь, а не светскую болтовню."
    }
    
    var personalitySocialFilter: String {
        personalityResult?.sections.flatMap(\.items).first(where: { $0.title == .socialFilter })?.description ?? "Обладает встроенным детектором на пустую болтовню."
    }
    
    var personalityEmotionalDepth: String {
        personalityResult?.sections.flatMap(\.items).first(where: { $0.title == .emotionalDepth })?.description ?? "Чувства раскрываются постепенно, но очень надолго."
    }

    var personalityTemperament: Int {
        personalityResult?.emotionalBar.first(where: { $0.title == .temperament })?.value ?? 5
    }

    var personalityThinking: Int {
        personalityResult?.emotionalBar.first(where: { $0.title == .thinking })?.value ?? 7
    }

    var personalityOrganization: Int {
        personalityResult?.emotionalBar.first(where: { $0.title == .organization })?.value ?? 3
    }

    var personalityRelationships: Int {
        personalityResult?.emotionalBar.first(where: { $0.title == .relationships })?.value ?? 6
    }

    var zodiacSignTitle: String? {
        guard let sign = personalityResult?.zodiacSign else { return nil }
        return HoroscopeType.allCases
            .first { $0.icon.contains(sign) || sign.contains($0.icon) }?.rawValue
    }

    init(authService: any AuthServiceProtocol,
         psychologyService: any PsychologyServiceProtocol) {
        self.authService = authService
        self.psychologyService = psychologyService

        setupSubscriptions()
    }

    deinit {
        cancellables.removeAll()
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] authState in
                guard let self else { return }
                self.authState = authState

                switch authState {
                    case .signedIn:
                        listenToPersonalityTests()
                    case .signedOut:
                        hasPersonalityTests = false
                        personalityResult = nil
                }
            }
            .store(in: &cancellables)

        psychologyService.historyDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, case .signedIn = authState else { return }
                listenToPersonalityTests()
            }
            .store(in: &cancellables)
    }

    private func listenToPersonalityTests() {
        Task {
            do {
                let history = try await psychologyService.fetchHistory()

                guard let latest = history.first(where: { $0.kind == .personality }) else {
                    hasPersonalityTests = false
                    personalityResult = nil
                    return
                }

                let detail = try await psychologyService.fetchHistoryDetails(id: latest.id)
                personalityResult = detail.personalityResult
                hasPersonalityTests = personalityResult != nil
            } catch {
                hasPersonalityTests = false
                personalityResult = nil
            }
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
            do {
                try await Task.sleep(for: AuthInput.authActionDelay)
                try await authService.createAccount(name: name, email: email, password: password)

                profileRoutes = []
                clearFields()
            } catch {
                showError(error.localizedDescription)
            }

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
            do {
                try await Task.sleep(for: AuthInput.authActionDelay)
                try await authService.signIn(email: email, password: password)

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

private enum AuthInput {
    static let minPasswordLength = 6
    static let minNameLength = 2
    static let authActionDelay = Duration.seconds(1)
}
