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

    var title: LocalizedStringResource {
        switch self {
            case .welcome: "Добро пожаловать"
            case .horoscope: "Гороскоп на неделю"
            case .daily: "Инсайт и совет дня"
            case .tests: "Тесты о вас и совместимость"
        }
    }

    var subtitle: LocalizedStringResource {
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
    @Published private(set) var showsResetCodeEntry = false

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showSignOutAlert = false
    @Published private(set) var isCheckingEmail = false
    @Published private(set) var isLoading = false
    @Published private(set) var loadingTitle: LocalizedStringResource = "Входим..."

    private var hasSession = false
    private var cancellables = Set<AnyCancellable>()

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol) {
        self.authService = authService

        if case .signedIn(let user) = authService.authState {
            hasSession = true
            name = user.name.capitalized
            prepareIncompleteProfile(user)
        }

        setupSubscriptions()

        if let message = authService.takeExpiredSessionMessage() {
            presentAlert(message)
        }
    }

    var isSignedIn: Bool {
        if case .signedIn = authService.authState { return true }
        return false
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }

    var introButtonTitle: LocalizedStringResource {
        isLastIntroPage ? "Начать" : "Далее"
    }

    var nameAndBirthTitle: LocalizedStringResource {
        isSignedIn ? "Когда вы родились?" : "Как вас зовут и когда вы родились?"
    }

    var emailButtonTitle: LocalizedStringResource {
        isCheckingEmail ? "Проверяем..." : "Далее"
    }

    private var isLastIntroPage: Bool {
        introPage == IntroPages.allCases.count - 1
    }

    var isOnlyStepOfSignedInUser: Bool {
        isSignedIn && onboardingRoutes.count == 1
    }

    private func setupSubscriptions() {
        authService.authStatePublisher
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

        hasSession = false
        isLoading = false
        onboardingRoutes = []
        presentAlert(authService.takeExpiredSessionMessage() ?? AppLanguage.text("Сессия истекла. Войдите снова"))
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
                hasSession = false
                isLoading = false
                onboardingRoutes = []
            } catch {
                presentAlert(error.userMessage)
            }
        }
    }

    func showNextIntroPage() {
        isLastIntroPage ? showSignUp() : withAnimation { introPage += 1 }
    }

    func showSignIn() {
        resetTextFields()
        resetRegistrationFields()
        onboardingRoutes.append(.signIn)
    }

    func showSignUp() {
        resetTextFields()
        resetRegistrationFields()
        onboardingRoutes.append(.nameAndBirth)
    }

    func showPasswordReset() {
        showsResetCodeEntry = false
        resetCode = ""
        newPassword = ""
        onboardingRoutes.append(.resetPassword)
    }

    func continueFromNameAndBirth() {
        if !isSignedIn, let message = nameError(displayName) {
            presentAlert(message)
            return
        }

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
        let routes = onboardingRoutes
        let sessionID = authService.sessionID

        func isCurrentRequest() -> Bool {
            onboardingRoutes == routes &&
            self.email.trimmingCharacters(in: .whitespacesAndNewlines) == email &&
            sessionID == authService.sessionID
        }

        Task {
            do {
                try await authService.ensureEmailAvailable(email: email)

                if isCurrentRequest() {
                    onboardingRoutes.append(.password)
                }
            } catch {
                if isCurrentRequest() {
                    presentAlert(error.userMessage)
                }
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

        guard !isLoading else { return }
        isLoading = true
        loadingTitle = "Входим..."
        
        var sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                try await authService.signIn(email: email, password: password)
                sessionID = authService.sessionID
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }

                if continueAfterSignIn() {
                    authService.finishOnboarding()
                    return
                }

                try await Task.sleep(for: .milliseconds(50))
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
        }
    }
    
    private func createAccount() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let message = passwordError(password) {
            presentAlert(message)
            return
        }

        isLoading = true
        loadingTitle = "Создаём аккаунт..."
        
        var sessionID = authService.sessionID
        
        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)
            
            do {
                try await authService.createAccount(name: displayName,
                                                    email: email,
                                                    password: password)
                sessionID = authService.sessionID
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                onboardingRoutes.append(.aiConsent)
                try await Task.sleep(for: .milliseconds(50))
                guard sessionID == authService.sessionID else { return }
                resetTextFields()
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }
            
            guard sessionID == authService.sessionID else { return }
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
        loadingTitle = "Отправляем..."

        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                try await authService.requestPasswordReset(email: email)
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                showsResetCodeEntry = true
                try await Task.sleep(for: .milliseconds(50))
            } catch {
                guard sessionID == authService.sessionID else { return }
                switch error as? NetworkError {
                    case .emailCodeRecentlyRequested, .emailCodeDailyLimit:
                        showsResetCodeEntry = true
                    default:
                        break
                }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
        }
    }

    func resetPassword() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = resetCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard code.count == InputLimits.resetCodeLength, code.allSatisfy(\.isNumber) else {
            presentAlert(AppLanguage.text("Введите 6-значный код из письма"))
            return
        }

        if let message = passwordError(newPassword) {
            presentAlert(message)
            return
        }

        guard !isLoading else { return }
        isLoading = true
        loadingTitle = "Сохраняем..."

        var sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                try await authService.resetPassword(email: email,
                                                    code: code,
                                                    newPassword: newPassword)
                sessionID = authService.sessionID
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }

                if continueAfterSignIn() {
                    authService.finishOnboarding()
                    return
                }

                try await Task.sleep(for: .milliseconds(50))
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
        }
    }

    func continueFromPsychotype() {
        guard !isLoading else { return }

        guard profileInfo.hasAllAnswers else {
            presentAlert(AppLanguage.text("Ответьте на все вопросы"))
            return
        }

        guard !isSignedIn else {
            onboardingRoutes.append(.aiConsent)
            return
        }

        createAccount()
    }

    func chooseAIConsent(_ allows: Bool) {
        guard !isLoading else { return }

        if case .signedIn(let user) = authService.authState, user.hasCompletedProfileInfo {
            allows ? giveAIConsent() : authService.finishOnboarding()
        } else {
            prepareProfile(allowsAIAnalysis: allows)
        }
    }

    private func giveAIConsent() {
        isLoading = true
        loadingTitle = "Сохраняем..."

        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                try await authService.giveAIConsent()
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                authService.finishOnboarding()
                return
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
        }
    }

    private func prepareProfile(allowsAIAnalysis: Bool) {
        guard isSignedIn else { return }

        var request = profileInfo
        request.dateOfBirth = BirthDateFormatter.dateString(date: birthDate)
        request.birthTime = knowsBirthTime ? BirthDateFormatter.timeString(date: birthTime) : ""
        let preparedRequest = request

        isLoading = true
        loadingTitle = "Сохраняем профиль и настройки"

        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                try await authService.updateProfileInfo(preparedRequest)
                guard sessionID == authService.sessionID else { return }

                if allowsAIAnalysis {
                    try await authService.giveAIConsent()
                }

                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                authService.finishOnboarding()
                return
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
        }
    }

    private func continueAfterSignIn() -> Bool {
        guard case .signedIn(let user) = authService.authState else { return false }

        name = user.name.capitalized
        password = ""

        if user.hasCompletedProfileInfo && user.allowsAIAnalysis {
            return true
        } else if user.hasCompletedProfileInfo {
            onboardingRoutes.append(.aiConsent)
        } else {
            prepareIncompleteProfile(user)
        }
        return false
    }

    private func prepareIncompleteProfile(_ user: UserModel) {
        birthDate = user.dateOfBirth.flatMap(BirthDateFormatter.date(string:)) ?? BirthDateFormatter.defaultDate
        knowsBirthTime = user.birthTime != nil
        birthTime = user.birthTime.flatMap(BirthDateFormatter.time(string:)) ?? BirthDateFormatter.defaultTime
        profileInfo = user.profileInfo
        onboardingRoutes = [.nameAndBirth]
    }

    private func resetTextFields() {
        name = ""
        email = ""
        password = ""
        resetCode = ""
        newPassword = ""
        showsResetCodeEntry = false
    }

    private func resetRegistrationFields() {
        birthDate = BirthDateFormatter.defaultDate
        knowsBirthTime = false
        birthTime = BirthDateFormatter.defaultTime
        profileInfo = ProfileInfoModel()
    }

    private func validateSignIn(email: String, password: String) -> String? {
        guard !email.isEmpty, !password.isEmpty else {
            return AppLanguage.text("Заполните почту и пароль")
        }
        return emailError(email)
    }

    private func nameError(_ name: String) -> String? {
        if name.isEmpty {
            return AppLanguage.text("Укажите имя")
        }
        if name.count < InputLimits.minNameLength {
            return AppLanguage.text("Имя должно содержать минимум \(InputLimits.minNameLength) символа")
        }
        if name.count > InputLimits.maxNameLength {
            return AppLanguage.text("Имя должно быть не длиннее \(InputLimits.maxNameLength) символов")
        }
        return nil
    }

    private func emailError(_ email: String) -> String? {
        if email.isEmpty {
            return AppLanguage.text("Укажите почту")
        }
        if !Self.isValidEmail(email) {
            return AppLanguage.text("Укажите корректный e-mail")
        }
        return nil
    }

    private func passwordError(_ password: String) -> String? {
        if password.isEmpty {
            return AppLanguage.text("Укажите пароль")
        }
        if password.count < InputLimits.minPasswordLength {
            return AppLanguage.text("Пароль должен быть не короче \(InputLimits.minPasswordLength) символов")
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
