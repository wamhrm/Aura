//
//  OnboardingViewModel.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import SwiftUI

enum OnboardingRoutes: Hashable {
    case nameAndBirth, email, password, signIn, resetPassword, psychotype, aiConsent, notifications, loading

    var progress: Double? {
        let signUpRoutes: [OnboardingRoutes] = [.nameAndBirth, .email, .password, .psychotype, .aiConsent, .notifications]
        guard let index = signUpRoutes.firstIndex(of: self) else { return nil }
        return Double(index + 1) / Double(signUpRoutes.count)
    }
}

enum OnboardingLoadingStage: CaseIterable {
    case profile, horoscope, insight

    var title: String {
        switch self {
            case .profile: "Сохраняем ваш профиль"
            case .horoscope: "Составляем гороскоп на неделю"
            case .insight: "Готовим инсайт дня"
        }
    }
}

enum IntroPages: Int, CaseIterable {
    case welcome, horoscope, daily, tests

    var icon: String? {
        switch self {
            case .welcome: nil
            case .horoscope: "moon.stars"
            case .daily: "sun.max"
            case .tests: "heart.text.square"
        }
    }

    var title: String {
        switch self {
            case .welcome: "Добро пожаловать"
            case .horoscope: "Гороскоп на неделю"
            case .daily: "Инсайт и совет дня"
            case .tests: "Тесты о вас и совместимость"
        }
    }

    var subtitle: String {
        switch self {
            case .welcome: "Гороскоп, инсайты и психологические тесты, которые помогают лучше понять себя и других"
            case .horoscope: "Прогноз о любви, здоровье и работе для вашего знака зодиака"
            case .daily: "Каждый день — короткая персональная подсказка о вашем состоянии и том, на что обратить внимание"
            case .tests: "Узнайте свой психотип и проверьте совместимость с партнёром"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject, AlertPresentable {
    @Published var onboardingRoutes: [OnboardingRoutes] = []
    @Published var introPage = 0

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

    private var hasEnteredBirthDate = false
    private var allowsAIAnalysis = false
    private var appleSignInNonce: String?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let onFinish: () -> Void

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         onFinish: @escaping () -> Void) {
        self.authService = authService
        self.contentService = contentService
        self.onFinish = onFinish

        if case .signedIn(let user) = authService.authState.value {
            name = user.name
            onboardingRoutes = [.nameAndBirth]
        }
    }

    var isSignedIn: Bool {
        if case .signedIn = authService.authState.value { return true }
        return false
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var introButtonTitle: String {
        isLastIntroPage ? "Начать" : "Далее"
    }

    var nameAndBirthTitle: String {
        isSignedIn ? "Когда вы родились?" : "Как вас зовут и когда вы родились?"
    }

    var createAccountButtonTitle: String {
        isLoading ? "Создаём аккаунт..." : "Создать аккаунт"
    }

    var signInButtonTitle: String {
        isLoading ? "Входим..." : "Войти"
    }

    var sendCodeButtonTitle: String {
        isLoading ? "Отправляем..." : "Отправить код"
    }

    var resetPasswordButtonTitle: String {
        isLoading ? "Сохраняем..." : "Сохранить пароль"
    }

    var aiConsentButtonTitle: String {
        isLoading ? "Сохраняем..." : "Разрешить"
    }

    var loadingTitle: String {
        hasLoadingFailed ? "Не удалось подготовить профиль" : "Составляем ваш профиль"
    }

    var loadingIcon: String {
        hasLoadingFailed ? "exclamationmark" : "sparkles"
    }

    private var isLastIntroPage: Bool {
        introPage == IntroPages.allCases.count - 1
    }

    func isCompleted(_ stage: OnboardingLoadingStage) -> Bool {
        completedLoadingStages.contains(stage)
    }

    func showNextIntroPage() {
        if isLastIntroPage {
            start()
        } else {
            withAnimation { introPage += 1 }
        }
    }

    func start() {
        onboardingRoutes.append(.nameAndBirth)
    }

    func showSignIn() {
        onboardingRoutes.append(.signIn)
    }

    func showSignUp() {
        onboardingRoutes = [.nameAndBirth]
    }

    func showPasswordReset() {
        isResetCodeSent = false
        resetCode = ""
        newPassword = ""
        onboardingRoutes.append(.resetPassword)
    }

    func continueFromNameAndBirth() {
        if !isSignedIn, let message = nameError(displayName) {
            presentAlert(message)
            return
        }

        hasEnteredBirthDate = true
        onboardingRoutes.append(isSignedIn ? .psychotype : .email)
    }

    func continueFromEmail() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = emailError(email) {
            presentAlert(message)
            return
        }

        onboardingRoutes.append(.password)
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
                presentAlert(error.userMessage)
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
                presentAlert(error.userMessage)
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
                presentAlert(error.userMessage)
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
                presentAlert(error.userMessage)
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
        guard profileInfo.hasAllAnswers else {
            presentAlert("Ответьте на все вопросы")
            return
        }

        onboardingRoutes.append(.aiConsent)
    }

    func chooseAIConsent(_ allows: Bool) {
        allowsAIAnalysis = allows

        // A returning user with a filled profile only lacked the consent
        if case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            allows ? giveAIConsent() : onFinish()
        } else {
            onboardingRoutes.append(.notifications)
        }
    }

    func continueFromNotifications() {
        onboardingRoutes.append(.loading)
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
                presentAlert(error.userMessage)
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
                presentAlert(error.userMessage)
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

                if response.horoscope == nil {
                    _ = try? await contentService.fetchCurrentHoroscope(for: userId)
                }
                await completeLoadingStage(.horoscope)

                if allowsAIAnalysis {
                    try? await authService.giveAIConsent()

                    _ = try? await contentService.fetchDailyInsight(for: userId)
                    await completeLoadingStage(.insight)
                }

                onFinish()
            } catch {
                alertMessage = error.userMessage
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

        // Auth screens are dropped from the stack, so back can't return to them
        if user.hasCompletedProfileInfo && user.allowsAIAnalysis {
            onFinish()
        } else if user.hasCompletedProfileInfo {
            onboardingRoutes = [.aiConsent]
        } else if hasEnteredBirthDate {
            onboardingRoutes = [.nameAndBirth, .psychotype]
        } else {
            onboardingRoutes = [.nameAndBirth]
        }
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
