//
//  OnboardingViewModel.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import Combine
import Foundation
import SwiftUI

enum OnboardingRoutes: Hashable {
    case nameAndBirth, email, password, signIn, resetPassword, psychotype, aiConsent, loading

    var progress: Double? {
        let signUpRoutes: [OnboardingRoutes] = [.nameAndBirth, .email, .password, .psychotype, .aiConsent]
        guard let index = signUpRoutes.firstIndex(of: self) else { return nil }
        return Double(index + 1) / Double(signUpRoutes.count)
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
    @Published var birthDate = BirthDateFormatter.defaultDate
    @Published var knowsBirthTime = false
    @Published var birthTime = BirthDateFormatter.defaultTime
    @Published var profileInfo = ProfileInfoModel()

    @Published var resetCode = ""
    @Published var newPassword = ""
    @Published private(set) var isResetCodeSent = false

    @Published private(set) var hasLoadingFailed = false

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showSignOutAlert = false
    @Published private(set) var isLoading = false

    private var hasEnteredBirthDate = false
    private var allowsAIAnalysis = false
    private var hasSession = false
    private var preparationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol) {
        self.authService = authService

        if case .signedIn(let user) = authService.authState.value {
            hasSession = true
            name = user.name
            onboardingRoutes = [.nameAndBirth]
        }

        setupSubscriptions()

        if let message = authService.takeExpiredSessionMessage() {
            presentAlert(message)
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
        hasLoadingFailed ? "Не удалось сохранить настройки" : "Сохраняем профиль и настройки"
    }

    var loadingIcon: String {
        hasLoadingFailed ? "exclamationmark" : "sparkles"
    }

    private var isLastIntroPage: Bool {
        introPage == IntroPages.allCases.count - 1
    }

    private var isOnlyStepOfSignedInUser: Bool {
        isSignedIn && onboardingRoutes.count == 1
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }

                switch $0 {
                    case .signedIn:
                        hasSession = true
                    case .signedOut:
                        handleSessionEnd()
                }
            }
            .store(in: &cancellables)
    }

    private func handleSessionEnd() {
        guard hasSession else { return }

        preparationTask?.cancel()
        hasSession = false
        hasLoadingFailed = false
        onboardingRoutes = []
        presentAlert(authService.takeExpiredSessionMessage() ?? "Сессия истекла. Войдите снова")
    }

    func hidesSystemBackButton(route: OnboardingRoutes) -> Bool {
        route == .loading || isOnlyStepOfSignedInUser
    }

    func goBack() {
        if isOnlyStepOfSignedInUser {
            showSignOutAlert = true
        } else if !onboardingRoutes.isEmpty {
            onboardingRoutes.removeLast()
        }
    }

    func signOut() {
        Task {
            do {
                try await authService.signOut()
                preparationTask?.cancel()
                hasSession = false
                onboardingRoutes = []
            } catch {
                presentAlert(error.userMessage)
            }
        }
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

        guard code.count == InputLimits.resetCodeLength, code.allSatisfy(\.isNumber) else {
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

    func continueFromPsychotype() {
        guard profileInfo.hasAllAnswers else {
            presentAlert("Ответьте на все вопросы")
            return
        }

        onboardingRoutes.append(.aiConsent)
    }

    func chooseAIConsent(_ allows: Bool) {
        allowsAIAnalysis = allows
        authService.noteAIConsentAsked()

        if case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            allows ? giveAIConsent() : finishOnboarding()
        } else {
            onboardingRoutes.append(.loading)
            prepareProfile()
        }
    }

    func retryLoading() {
        prepareProfile()
    }

    private func giveAIConsent() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.giveAIConsent()
                finishOnboarding()
            } catch {
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }

    private func prepareProfile() {
        guard preparationTask == nil, isSignedIn else { return }
        hasLoadingFailed = false

        var request = profileInfo
        request.dateOfBirth = BirthDateFormatter.dateString(date: birthDate)
        request.birthTime = knowsBirthTime ? BirthDateFormatter.timeString(date: birthTime) : ""

        preparationTask = Task {
            defer { preparationTask = nil }

            do {
                _ = try await authService.updateProfileInfo(request)
                try Task.checkCancellation()

                if allowsAIAnalysis {
                    try await authService.giveAIConsent()
                    try Task.checkCancellation()
                }

                finishOnboarding()
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                alertMessage = error.userMessage
                hasLoadingFailed = true
            }
        }
    }

    private func finishOnboarding() {
        authService.finishOnboarding()
    }

    private func continueAfterSignIn() {
        guard case .signedIn(let user) = authService.authState.value else { return }

        name = user.name
        password = ""

        if user.hasCompletedProfileInfo && user.allowsAIAnalysis {
            finishOnboarding()
        } else if user.hasCompletedProfileInfo {
            onboardingRoutes = [.aiConsent]
        } else if hasEnteredBirthDate {
            onboardingRoutes = [.nameAndBirth, .psychotype]
        } else {
            onboardingRoutes = [.nameAndBirth]
        }
    }

    private func validateSignIn(email: String, password: String) -> String? {
        guard !email.isEmpty, !password.isEmpty else {
            return "Заполните почту и пароль"
        }
        return emailError(email)
    }

    private func nameError(_ name: String) -> String? {
        if name.isEmpty {
            return "Укажите имя"
        }
        if name.count < InputLimits.minNameLength {
            return "Имя должно содержать минимум \(InputLimits.minNameLength) символа"
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
        if password.count < InputLimits.minPasswordLength {
            return "Пароль должен быть не короче \(InputLimits.minPasswordLength) символов"
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

