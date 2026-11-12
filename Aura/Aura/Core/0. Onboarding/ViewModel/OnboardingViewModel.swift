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
    case nameAndBirth, email, password, signIn, resetPassword, psychotype, aiConsent

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

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showSignOutAlert = false
    @Published private(set) var isCheckingEmail = false
    @Published private(set) var loadingTitle: String?

    private var hasEnteredBirthDate = false
    private var allowsAIAnalysis = false
    private var hasSession = false
    private var opensMainScreen = false
    private var coverTask: Task<Void, Never>?
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

    var emailButtonTitle: String {
        isCheckingEmail ? "Проверяем..." : "Далее"
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

        coverTask?.cancel()
        hasSession = false
        loadingTitle = nil
        onboardingRoutes = []
        presentAlert(authService.takeExpiredSessionMessage() ?? "Сессия истекла. Войдите снова")
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
                coverTask?.cancel()
                hasSession = false
                loadingTitle = nil
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
        onboardingRoutes.append(.nameAndBirth)
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

        guard !isCheckingEmail else { return }

        isCheckingEmail = true

        Task {
            do {
                try await authService.ensureEmailAvailable(email: email)
                onboardingRoutes.append(.password)
            } catch {
                presentAlert(error.userMessage)
            }

            isCheckingEmail = false
        }
    }

    func continueFromPassword() {
        if let message = passwordError(password) {
            presentAlert(message)
            return
        }

        onboardingRoutes.append(.psychotype)
    }

    func signIn() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = validateSignIn(email: email, password: password) {
            presentAlert(message)
            return
        }

        performCovered("Входим...") {
            try await self.authService.signIn(email: email, password: self.password)
        } commit: {
            self.opensMainScreen = self.continueAfterSignIn()
        } leaveCover: {
            guard self.opensMainScreen else { return false }
            self.authService.finishOnboarding()
            return true
        }
    }

    func requestPasswordReset() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = emailError(email) {
            presentAlert(message)
            return
        }

        performCovered("Отправляем...") {
            try await self.authService.requestPasswordReset(email: email)
        } commit: {
            self.isResetCodeSent = true
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

        performCovered("Сохраняем...") {
            try await self.authService.resetPassword(email: email, code: code, newPassword: self.newPassword)
        } commit: {
            self.opensMainScreen = self.continueAfterSignIn()
        } leaveCover: {
            guard self.opensMainScreen else { return false }
            self.authService.finishOnboarding()
            return true
        }
    }

    func continueFromPsychotype() {
        guard profileInfo.hasAllAnswers else {
            presentAlert("Ответьте на все вопросы")
            return
        }

        guard !isSignedIn else {
            onboardingRoutes.append(.aiConsent)
            return
        }

        createAccount()
    }

    private func createAccount() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = passwordError(password) {
            presentAlert(message)
            return
        }

        performCovered("Создаём аккаунт...") {
            try await self.authService.createAccount(
                name: self.displayName,
                email: email,
                password: self.password)
            self.password = ""
        } commit: {
            self.onboardingRoutes.append(.aiConsent)
        }
    }

    func chooseAIConsent(_ allows: Bool) {
        allowsAIAnalysis = allows
        authService.noteAIConsentAsked()

        if case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            allows ? giveAIConsent() : authService.finishOnboarding()
        } else {
            prepareProfile()
        }
    }

    private func giveAIConsent() {
        performCovered("Сохраняем...") {
            try await self.authService.giveAIConsent()
        } leaveCover: {
            self.authService.finishOnboarding()
            return true
        }
    }

    private func prepareProfile() {
        guard isSignedIn else { return }

        var request = profileInfo
        request.dateOfBirth = BirthDateFormatter.dateString(date: birthDate)
        request.birthTime = knowsBirthTime ? BirthDateFormatter.timeString(date: birthTime) : ""
        let preparedRequest = request

        performCovered("Сохраняем профиль и настройки") {
            _ = try await self.authService.updateProfileInfo(preparedRequest)
            try Task.checkCancellation()

            if self.allowsAIAnalysis {
                try await self.authService.giveAIConsent()
                try Task.checkCancellation()
            }
        } leaveCover: {
            self.authService.finishOnboarding()
            return true
        }
    }

    private func performCovered(_ title: String,
                                operation: @escaping () async throws -> Void,
                                commit: @escaping () -> Void = {},
                                leaveCover: @escaping () -> Bool = { false }) {
        guard loadingTitle == nil else { return }

        loadingTitle = title
        coverTask = Task {
            defer { self.coverTask = nil }

            do {
                try await CoveredTransition.run(hide: { self.loadingTitle = nil },
                                                operation: operation,
                                                commit: commit,
                                                leaveCover: leaveCover)
            } catch {
                if error is CancellationError { return }
                if case NetworkError.cancelled = error { return }
                self.presentAlert(error.userMessage)
            }
        }
    }

    private func continueAfterSignIn() -> Bool {
        guard case .signedIn(let user) = authService.authState.value else { return false }

        name = user.name
        password = ""

        if user.hasCompletedProfileInfo && user.allowsAIAnalysis {
            return true
        } else if user.hasCompletedProfileInfo {
            onboardingRoutes.append(.aiConsent)
        } else if hasEnteredBirthDate {
            onboardingRoutes.append(.psychotype)
        } else {
            onboardingRoutes = [.nameAndBirth]
        }
        return false
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
