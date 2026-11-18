//
//  OnboardingViewModelTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class OnboardingViewModelTests: AuraUnitTestCase {
    func test_lateProfileResponse_doesNotEndLoadingOfANewSignIn() async {
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil))
        auth.profileSaveDelay = .milliseconds(100)
        let viewModel = makeViewModel(auth: auth)
        viewModel.chooseAIConsent(true)
        await waitUntil { auth.savedProfile != nil }
        auth.endExpiredSession()
        await waitUntil { !viewModel.isLoading }
        auth.serverUser = makeUser()
        viewModel.email = "anna@mail.ru"
        viewModel.password = "12345678"
        viewModel.signIn()
        await waitUntil { auth.profileSaveFinished }

        XCTAssertTrue(viewModel.isLoading)
        await waitUntil { auth.showsMainScreen }
        XCTAssertTrue(viewModel.onboardingRoutes.isEmpty)
        XCTAssertEqual(auth.aiConsentCount, 0)
    }

    func test_signIn_discardsTheAbandonedRegistrationDraft() async {
        let auth = MockAuthService()
        auth.serverUser = makeUser(dateOfBirth: nil, socialType: nil)
        let viewModel = makeViewModel(auth: auth)
        viewModel.birthDate = BirthDateFormatter.date(string: "01.01.1990")!
        viewModel.knowsBirthTime = true
        viewModel.profileInfo.gender = "man"
        viewModel.profileInfo.socialType = "introvert"
        viewModel.onboardingRoutes = [.nameAndBirth, .email]
        viewModel.showSignIn()

        await signIn(viewModel, auth: auth)

        XCTAssertEqual(viewModel.onboardingRoutes, [.nameAndBirth])
        XCTAssertEqual(viewModel.birthDate, BirthDateFormatter.defaultDate)
        XCTAssertFalse(viewModel.knowsBirthTime)
        XCTAssertNil(viewModel.profileInfo.socialType)
    }

    func test_emailResponse_afterGoingBack_doesNotOpenPassword() async {
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"
        viewModel.onboardingRoutes = [.nameAndBirth, .email]
        auth.beforeEmailResponse = { viewModel.goBack() }

        viewModel.continueFromEmail()
        await waitUntil { !viewModel.isCheckingEmail }

        XCTAssertEqual(viewModel.onboardingRoutes, [.nameAndBirth])
        XCTAssertFalse(viewModel.showAlert)
    }

    func test_emailResponse_afterEditingTheAddress_doesNotOpenPassword() async {
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"
        viewModel.onboardingRoutes = [.email]
        auth.beforeEmailResponse = { viewModel.email = "other@mail.ru" }

        viewModel.continueFromEmail()
        await waitUntil { !viewModel.isCheckingEmail }

        XCTAssertEqual(viewModel.onboardingRoutes, [.email])
        XCTAssertFalse(viewModel.showAlert)
    }

    func test_nameLongerThanTheLimit_doesNotOpenTheEmailStep() {
        let viewModel = makeViewModel(auth: MockAuthService())
        viewModel.name = String(repeating: "A", count: InputLimits.maxNameLength + 1)

        viewModel.continueFromNameAndBirth()

        XCTAssertTrue(viewModel.onboardingRoutes.isEmpty)
        XCTAssertTrue(viewModel.showAlert)
    }

    func test_failedSignOut_showsError_andKeepsCurrentStep() async {
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let viewModel = makeViewModel(auth: auth)
        viewModel.onboardingRoutes = [.aiConsent]
        auth.errorToThrow = serverError

        viewModel.signOut()
        await waitUntil { viewModel.showAlert }

        XCTAssertEqual(viewModel.onboardingRoutes, [.aiConsent])
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        guard case .signedIn = auth.authState.value else { return XCTFail("Session was ended") }
    }

    private func makeViewModel(auth: MockAuthService) -> OnboardingViewModel {
        OnboardingViewModel(authService: auth)
    }

    private func signIn(_ viewModel: OnboardingViewModel, auth: MockAuthService) async {
        viewModel.email = "anna@mail.ru"
        viewModel.password = "12345678"
        viewModel.signIn()
        await waitUntil { !viewModel.isLoading || auth.showsMainScreen }
    }

    func test_takenEmail_staysOnEmailStep() async {
        let auth = MockAuthService()
        auth.emailTaken = true
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"

        viewModel.continueFromEmail()
        await waitUntil { viewModel.showAlert }

        XCTAssertTrue(viewModel.onboardingRoutes.isEmpty)
        XCTAssertEqual(viewModel.alertMessage, "Пользователь уже зарегистрирован")
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_availableEmail_opensPasswordStep() async {
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"

        viewModel.continueFromEmail()
        await waitUntil { viewModel.onboardingRoutes == [.password] }

        XCTAssertFalse(viewModel.showAlert)
        XCTAssertEqual(auth.emailCheckCount, 1)
    }

    // MARK: - Forms
    func test_password_ofSevenCharacters_isRejected_andOfEightIsAccepted() {
        // Given
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"

        // When
        viewModel.password = "1234567"
        viewModel.continueFromPassword()
        let alertAfterSevenCharacters = viewModel.alertMessage
        viewModel.password = "12345678"
        viewModel.continueFromPassword()

        // Then
        XCTAssertEqual(alertAfterSevenCharacters, "Пароль должен быть не короче 8 символов")
        XCTAssertEqual(viewModel.onboardingRoutes, [.psychotype])
        XCTAssertEqual(auth.createAccountCount, 0)
    }

    func test_showSignIn_clearsTheRegistrationFields() {
        // Given
        let viewModel = makeViewModel(auth: MockAuthService())
        viewModel.name = "Анна"
        viewModel.email = "anna@mail.ru"
        viewModel.password = "12345678"

        // When
        viewModel.showSignIn()

        // Then
        XCTAssertEqual(viewModel.onboardingRoutes, [.signIn])
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
    }

    func test_resetCode_withLetters_showsAlert_andSendsNothing() {
        // Given
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth: auth)
        viewModel.resetCode = "12a456"
        viewModel.newPassword = "12345678"

        // When
        viewModel.resetPassword()

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Введите 6-значный код из письма")
        XCTAssertEqual(auth.resetPasswordCount, 0)
    }

    func test_requestPasswordReset_whenCodeIsAlreadySent_opensTheCodeForm() async {
        let auth = MockAuthService()
        auth.errorToThrow = NetworkError.emailCodeRecentlyRequested("Код уже отправлен")
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"

        viewModel.requestPasswordReset()
        await waitUntil { !viewModel.isLoading }

        XCTAssertTrue(viewModel.isResetCodeSent)
        XCTAssertEqual(viewModel.alertMessage, "Код уже отправлен")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(auth.showsMainScreen)
    }

    func test_requestPasswordReset_whenServerFails_keepsTheCodeFormClosed() async {
        let auth = MockAuthService()
        auth.errorToThrow = serverError
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"

        viewModel.requestPasswordReset()
        await waitUntil { !viewModel.isLoading }

        XCTAssertFalse(viewModel.isResetCodeSent)
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertTrue(viewModel.showAlert)
    }

    // MARK: - Where the user lands after signing in
    func test_signIn_withFullProfileAndConsent_finishesOnboarding() async {
        // Given
        let auth = MockAuthService()
        auth.serverUser = makeUser()
        let viewModel = makeViewModel(auth: auth)

        // When
        await signIn(viewModel, auth: auth)

        // Then
        XCTAssertTrue(auth.showsMainScreen)
        XCTAssertTrue(viewModel.isLoading)
    }

    func test_signIn_withFullProfileWithoutConsent_asksOnlyForTheConsent() async {
        // Given
        let auth = MockAuthService()
        auth.serverUser = makeUser(hasAIConsent: false)
        let viewModel = makeViewModel(auth: auth)

        // When
        await signIn(viewModel, auth: auth)

        // Then
        XCTAssertEqual(viewModel.onboardingRoutes, [.aiConsent])
    }

    func test_signIn_withEmptyProfile_opensTheFirstStep_withTheNameFilled() async {
        // Given
        let auth = MockAuthService()
        auth.serverUser = makeUser(dateOfBirth: nil)
        let viewModel = makeViewModel(auth: auth)

        // When
        await signIn(viewModel, auth: auth)

        // Then
        XCTAssertEqual(viewModel.onboardingRoutes, [.nameAndBirth])
        XCTAssertEqual(viewModel.name, "Дмитрий")
    }

    func test_registration_createsTheAccount_onlyAfterThePsychotypeStep() async {
        let auth = MockAuthService()
        auth.serverUser = makeUser(dateOfBirth: nil)
        let viewModel = makeViewModel(auth: auth)
        viewModel.name = "Анна"
        viewModel.email = "anna@mail.ru"
        viewModel.password = "12345678"

        viewModel.continueFromNameAndBirth()
        viewModel.continueFromEmail()
        await waitUntil { viewModel.onboardingRoutes == [.email, .password] }
        viewModel.continueFromPassword()

        XCTAssertEqual(viewModel.onboardingRoutes, [.email, .password, .psychotype])
        XCTAssertEqual(auth.createAccountCount, 0)

        viewModel.continueFromPsychotype()
        XCTAssertEqual(viewModel.alertMessage, "Ответьте на все вопросы")
        XCTAssertEqual(auth.createAccountCount, 0)

        viewModel.profileInfo.gender = "man"
        viewModel.profileInfo.socialType = "introvert"
        viewModel.profileInfo.conflictStyle = "mediator"
        viewModel.profileInfo.emotionalCore = "logic"
        viewModel.profileInfo.decisionStyle = "planner"
        viewModel.profileInfo.coreFocus = "stability"
        viewModel.continueFromPsychotype()
        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(auth.createAccountCount, 1)
        XCTAssertEqual(viewModel.onboardingRoutes, [.email, .password, .psychotype, .aiConsent])
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
    }

    func test_signedInUser_continuesFromPsychotype_withoutCreatingAnAccount() {
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil))
        let viewModel = makeViewModel(auth: auth)
        viewModel.onboardingRoutes = [.psychotype]
        viewModel.profileInfo.gender = "man"
        viewModel.profileInfo.socialType = "introvert"
        viewModel.profileInfo.conflictStyle = "mediator"
        viewModel.profileInfo.emotionalCore = "logic"
        viewModel.profileInfo.decisionStyle = "planner"
        viewModel.profileInfo.coreFocus = "stability"

        viewModel.continueFromPsychotype()

        XCTAssertEqual(auth.createAccountCount, 0)
        XCTAssertEqual(viewModel.onboardingRoutes, [.psychotype, .aiConsent])
    }

    func test_failedAccountCreation_staysOnThePsychotypeStep() async {
        let auth = MockAuthService()
        auth.errorToThrow = serverError
        let viewModel = makeViewModel(auth: auth)
        viewModel.name = "Анна"
        viewModel.email = "anna@mail.ru"
        viewModel.password = "12345678"
        viewModel.onboardingRoutes = [.psychotype]
        viewModel.profileInfo.gender = "man"
        viewModel.profileInfo.socialType = "introvert"
        viewModel.profileInfo.conflictStyle = "mediator"
        viewModel.profileInfo.emotionalCore = "logic"
        viewModel.profileInfo.decisionStyle = "planner"
        viewModel.profileInfo.coreFocus = "stability"

        viewModel.continueFromPsychotype()
        await waitUntil { viewModel.showAlert }

        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertEqual(viewModel.onboardingRoutes, [.psychotype])
        XCTAssertEqual(viewModel.password, "12345678")
    }

    // MARK: - AI consent
    func test_profilePreparation_whenConsentFails_showsError_andAllowsRetry() async {
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil))
        auth.serverUser = makeUser(hasAIConsent: false)
        auth.aiConsentError = serverError
        let viewModel = makeViewModel(auth: auth)

        viewModel.chooseAIConsent(true)
        await waitUntil { viewModel.showAlert || auth.showsMainScreen }

        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.onboardingRoutes, [.nameAndBirth])
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(auth.showsMainScreen)

        auth.aiConsentError = nil
        viewModel.chooseAIConsent(true)
        await waitUntil { auth.showsMainScreen }
    }

    func test_returningUser_decliningConsent_finishesWithoutARequest() {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let viewModel = makeViewModel(auth: auth)

        // When
        viewModel.chooseAIConsent(false)

        // Then
        XCTAssertTrue(auth.showsMainScreen)
        XCTAssertEqual(auth.aiConsentCount, 0)
    }

    func test_returningUser_allowingConsent_savesIt_andFinishes() async {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let viewModel = makeViewModel(auth: auth)

        // When
        viewModel.chooseAIConsent(true)
        await waitUntil { auth.showsMainScreen }

        // Then
        XCTAssertEqual(auth.aiConsentCount, 1)
    }

    func test_newUser_decliningConsent_savesProfile_andFinishesWithoutConsentRequest() async {
        // Given
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil))
        auth.serverUser = makeUser(hasAIConsent: false)
        let viewModel = makeViewModel(auth: auth)

        // When
        viewModel.chooseAIConsent(false)
        await waitUntil { auth.showsMainScreen }

        // Then
        XCTAssertNotNil(auth.savedProfile)
        XCTAssertEqual(auth.aiConsentCount, 0)
    }

    func test_sessionExpiration_duringProfileSave_doesNotContinueOnboarding() async {
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil))
        auth.profileSaveDelay = .milliseconds(100)
        let viewModel = makeViewModel(auth: auth)
        viewModel.chooseAIConsent(true)
        await waitUntil { auth.savedProfile != nil }

        auth.endExpiredSession()
        await waitUntil { auth.profileSaveFinished }

        XCTAssertFalse(auth.showsMainScreen)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.onboardingRoutes.isEmpty)
        XCTAssertEqual(auth.aiConsentCount, 0)
        XCTAssertEqual(viewModel.alertMessage, "Сессия истекла. Войдите снова")
    }

    func test_welcome_explainsWhyTheSessionEnded() {
        let auth = MockAuthService(user: makeUser())
        auth.endExpiredSession()

        let viewModel = makeViewModel(auth: auth)

        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.alertMessage, "Сессия истекла. Войдите снова")
        XCTAssertTrue(viewModel.onboardingRoutes.isEmpty)
    }

}
