//
//  OnboardingViewModel.swift
//  Aura
//
//  Created by ddorsat on 27.10.2026.
//

import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import SwiftUI

enum OnboardingStep: Hashable {
    case intro
    case nameAndBirth
    case email
    case password
    case signIn
    case resetPassword
    case psychotype
    case aiConsent
    case notifications
    case loading
}

enum OnboardingLoadingStage: CaseIterable {
    case profile
    case horoscope
    case insight

    var title: String {
        switch self {
            case .profile: "Сохраняем ваш профиль"
            case .horoscope: "Составляем гороскоп на неделю"
            case .insight: "Готовим инсайт дня"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject, LoadingStatePresentable {
    @Published private(set) var step: OnboardingStep

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var birthDate = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    @Published var knowsBirthTime = false
    @Published var birthTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @Published var profileInfo = ProfileInfoModel()

    @Published var resetCode = ""
    @Published var newPassword = ""
    @Published private(set) var isResetCodeSent = false

    @Published private(set) var loadingStages: [OnboardingLoadingStage] = []
    @Published private(set) var completedLoadingStages: [OnboardingLoadingStage] = []
    @Published private(set) var hasLoadingFailed = false

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false

    static let birthDateRange = (Calendar.current.date(from: DateComponents(year: 1920)) ?? .distantPast)...Date()

    private let signUpSteps: [OnboardingStep] = [.nameAndBirth, .email, .password, .psychotype, .aiConsent, .notifications]
    private var history: [OnboardingStep] = []
    private var hasEnteredBirthDate = false
    private var allowsAIAnalysis = false
    private var appleSignInNonce: String?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let storage: any LocalStorageProtocol
    private let onFinish: () -> Void

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         storage: any LocalStorageProtocol = LocalStorage(),
         onFinish: @escaping () -> Void) {
        self.authService = authService
        self.contentService = contentService
        self.storage = storage
        self.onFinish = onFinish

        if case .signedIn(let user) = authService.authState.value {
            name = user.name
            step = .nameAndBirth
        } else {
            step = .intro
        }
    }

    var isSignedIn: Bool {
        if case .signedIn = authService.authState.value { return true }
        return false
    }

    var canGoBack: Bool {
        !history.isEmpty
    }

    var progress: Double? {
        guard let index = signUpSteps.firstIndex(of: step) else { return nil }
        return Double(index + 1) / Double(signUpSteps.count)
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func start() {
        go(to: .nameAndBirth)
    }

    func showSignIn() {
        go(to: .signIn)
    }

    func showSignUp() {
        history = [.intro]
        withAnimation { step = .nameAndBirth }
    }

    func showPasswordReset() {
        isResetCodeSent = false
        resetCode = ""
        newPassword = ""
        go(to: .resetPassword)
    }

    func back() {
        guard let previous = history.popLast() else { return }
        withAnimation { step = previous }
    }

    func continueFromNameAndBirth() {
        if !isSignedIn, let message = nameError(displayName) {
            presentAlert(message)
            return
        }

        hasEnteredBirthDate = true
        go(to: isSignedIn ? .psychotype : .email)
    }

    func continueFromEmail() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = emailError(email) {
            presentAlert(message)
            return
        }

        go(to: .password)
    }

    func createAccount() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = passwordError(password) {
            presentAlert(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.createAccount(name: displayName, email: email, password: password)
                continueAfterSignIn()
            } catch {
                presentAlert(error.localizedDescription)
            }

            isLoading = false
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
            do {
                try await authService.signIn(email: email, password: password)
                continueAfterSignIn()
            } catch {
                presentAlert(error.localizedDescription)
            }

            isLoading = false
        }
    }

    func requestPasswordReset() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = emailError(email) {
            presentAlert(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.requestPasswordReset(email: email)
                withAnimation { isResetCodeSent = true }
            } catch {
                presentAlert(error.localizedDescription)
            }

            isLoading = false
        }
    }

    func resetPassword() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = resetCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard code.count == ResetInput.codeLength, code.allSatisfy(\.isNumber) else {
            presentAlert("Введите 6-значный код из письма")
            return
        }

        if let message = passwordError(newPassword) {
            presentAlert(message)
            return
        }

        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.resetPassword(email: email, code: code, newPassword: newPassword)
                continueAfterSignIn()
            } catch {
                presentAlert(error.localizedDescription)
            }

            isLoading = false
        }
    }

    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.makeNonce()
        appleSignInNonce = nonce
        request.requestedScopes = [.fullName]
        request.nonce = Self.sha256(nonce)
    }

    func completeAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
        switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let tokenData = credential.identityToken,
                      let identityToken = String(data: tokenData, encoding: .utf8),
                      let nonce = appleSignInNonce else {
                    presentAlert("Не удалось войти через Apple")
                    return
                }

                let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
                signInWithApple(identityToken: identityToken,
                                authorizationCode: authorizationCode,
                                nonce: nonce,
                                name: displayName.isEmpty ? credential.fullName?.givenName : displayName)
            case .failure(let error):
                guard (error as? ASAuthorizationError)?.code != .canceled else { return }
                presentAlert("Не удалось войти через Apple")
        }
    }

    func continueFromPsychotype() {
        guard profileInfo.gender != nil,
              profileInfo.socialType != nil,
              profileInfo.conflictStyle != nil,
              profileInfo.emotionalCore != nil,
              profileInfo.decisionStyle != nil,
              profileInfo.coreFocus != nil else {
            presentAlert("Ответьте на все вопросы")
            return
        }

        go(to: .aiConsent)
    }

    func chooseAIConsent(_ allows: Bool) {
        allowsAIAnalysis = allows

        // A returning user with a filled profile only lacked the consent
        if case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            allows ? giveAIConsent() : onFinish()
        } else {
            go(to: .notifications)
        }
    }

    func continueFromNotifications() {
        go(to: .loading)
        prepareProfile()
    }

    func retryLoading() {
        prepareProfile()
    }

    private func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.signInWithApple(identityToken: identityToken,
                                                      authorizationCode: authorizationCode,
                                                      nonce: nonce,
                                                      name: name)
                continueAfterSignIn()
            } catch {
                presentAlert(error.localizedDescription)
            }

            isLoading = false
        }
    }

    private func giveAIConsent() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.giveAIConsent()
                onFinish()
            } catch {
                presentAlert(error.localizedDescription)
            }

            isLoading = false
        }
    }

    private func prepareProfile() {
        hasLoadingFailed = false
        completedLoadingStages = []
        loadingStages = allowsAIAnalysis ? OnboardingLoadingStage.allCases : [.profile, .horoscope]

        var request = profileInfo
        request.dateOfBirth = format(birthDate, "dd.MM.yyyy")
        request.birthTime = knowsBirthTime ? format(birthTime, "HH:mm") : ""

        Task {
            do {
                let response = try await authService.updateProfileInfo(request)
                let userId = response.user.id
                await completeLoadingStage(.profile)

                if let horoscope = response.horoscope {
                    storage.save(horoscope, for: StorageKeys.horoscope, userId: userId)
                } else if let horoscope = try? await contentService.fetchCurrentHoroscope() {
                    storage.save(horoscope, for: StorageKeys.horoscope, userId: userId)
                }
                await completeLoadingStage(.horoscope)

                if allowsAIAnalysis {
                    try? await authService.giveAIConsent()

                    if let insight = try? await contentService.fetchDailyInsight() {
                        storage.save(insight, for: StorageKeys.dailyInsight, userId: userId)
                    }
                    await completeLoadingStage(.insight)
                }

                onFinish()
            } catch {
                alertMessage = error.localizedDescription
                hasLoadingFailed = true
            }
        }
    }

    // Keeps each checkmark on screen for a moment, otherwise the stages flash by
    private func completeLoadingStage(_ stage: OnboardingLoadingStage) async {
        withAnimation { completedLoadingStages.append(stage) }
        try? await Task.sleep(for: .seconds(0.8))
    }

    private func continueAfterSignIn() {
        guard case .signedIn(let user) = authService.authState.value else { return }

        name = user.name
        password = ""

        if user.hasCompletedProfileInfo && user.allowsAIAnalysis {
            onFinish()
        } else if user.hasCompletedProfileInfo {
            history = []
            withAnimation { step = .aiConsent }
        } else if hasEnteredBirthDate {
            history = [.nameAndBirth]
            withAnimation { step = .psychotype }
        } else {
            history = []
            withAnimation { step = .nameAndBirth }
        }
    }

    private func go(to nextStep: OnboardingStep) {
        history.append(step)
        withAnimation { step = nextStep }
    }

    private func format(_ date: Date, _ dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }

    private func validateSignIn(email: String, password: String) -> String? {
        guard !email.isEmpty, !password.isEmpty else {
            return "Заполните почту и пароль"
        }
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

    private static func makeNonce() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        return Data(bytes).base64EncodedString()
    }

    private static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
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

private enum ResetInput {
    static let codeLength = 6
}
