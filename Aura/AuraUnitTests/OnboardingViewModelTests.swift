//
//  OnboardingViewModelTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class OnboardingViewModelTests: XCTestCase {
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

    private func signIn(_ viewModel: OnboardingViewModel) async {
        viewModel.email = "anna@mail.ru"
        viewModel.password = "12345678"
        viewModel.signIn()
        await waitUntil { !viewModel.isLoading }
    }

    // MARK: - Forms
    func test_password_ofSevenCharacters_isRejected_andOfEightIsAccepted() async {
        // Given
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth: auth)
        viewModel.email = "anna@mail.ru"

        // When
        viewModel.password = "1234567"
        viewModel.createAccount()
        let alertAfterSevenCharacters = viewModel.alertMessage
        viewModel.password = "12345678"
        viewModel.createAccount()
        await waitUntil { auth.createAccountCount == 1 }

        // Then
        XCTAssertEqual(alertAfterSevenCharacters, "Пароль должен быть не короче 8 символов")
        XCTAssertEqual(auth.createAccountCount, 1)
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

    // MARK: - Where the user lands after signing in
    func test_signIn_withFullProfileAndConsent_finishesOnboarding() async {
        // Given
        let auth = MockAuthService()
        auth.serverUser = makeUser()
        let viewModel = makeViewModel(auth: auth)

        // When
        await signIn(viewModel)

        // Then
        XCTAssertTrue(auth.showsMainScreen)
    }

    func test_signIn_withFullProfileWithoutConsent_asksOnlyForTheConsent() async {
        // Given
        let auth = MockAuthService()
        auth.serverUser = makeUser(hasAIConsent: false)
        let viewModel = makeViewModel(auth: auth)

        // When
        await signIn(viewModel)

        // Then
        XCTAssertEqual(viewModel.onboardingRoutes, [.aiConsent])
    }

    func test_signIn_withEmptyProfile_opensTheFirstStep_withTheNameFilled() async {
        // Given
        let auth = MockAuthService()
        auth.serverUser = makeUser(dateOfBirth: nil, gender: nil)
        let viewModel = makeViewModel(auth: auth)

        // When
        await signIn(viewModel)

        // Then
        XCTAssertEqual(viewModel.onboardingRoutes, [.nameAndBirth])
        XCTAssertEqual(viewModel.name, "Дмитрий")
    }

    func test_registration_afterTheBirthDateStep_continuesWithTheQuestions() async {
        // Given
        let auth = MockAuthService()
        auth.serverUser = makeUser(dateOfBirth: nil, gender: nil)
        let viewModel = makeViewModel(auth: auth)
        viewModel.name = "Анна"
        viewModel.email = "anna@mail.ru"
        viewModel.password = "12345678"
        viewModel.continueFromNameAndBirth()

        // When
        viewModel.createAccount()
        await waitUntil { !viewModel.isLoading }

        // Then
        XCTAssertEqual(viewModel.onboardingRoutes, [.nameAndBirth, .psychotype])
    }

    // MARK: - AI consent
    func test_profilePreparation_whenConsentFails_showsError_andAllowsRetry() async {
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil, gender: nil))
        auth.serverUser = makeUser(hasAIConsent: false)
        auth.aiConsentError = serverError
        let viewModel = makeViewModel(auth: auth)

        viewModel.chooseAIConsent(true)
        await waitUntil { viewModel.hasLoadingFailed || auth.showsMainScreen }

        XCTAssertTrue(viewModel.hasLoadingFailed)
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertFalse(auth.showsMainScreen)

        auth.aiConsentError = nil
        viewModel.retryLoading()
        await waitUntil { auth.showsMainScreen }
        XCTAssertFalse(viewModel.hasLoadingFailed)
    }

    func test_returningUser_decliningConsent_finishesWithoutARequest() {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let viewModel = makeViewModel(auth: auth)

        // When
        viewModel.chooseAIConsent(false)

        // Then
        XCTAssertTrue(auth.showsMainScreen)
        XCTAssertTrue(auth.didAskAIConsent)
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
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil, gender: nil))
        auth.serverUser = makeUser(hasAIConsent: false)
        let viewModel = makeViewModel(auth: auth)

        // When
        viewModel.chooseAIConsent(false)
        await waitUntil { auth.showsMainScreen }

        // Then
        XCTAssertNotNil(auth.savedProfile)
        XCTAssertEqual(auth.aiConsentCount, 0)
        XCTAssertFalse(viewModel.hasLoadingFailed)
    }

    func test_sessionExpiration_duringProfileSave_cancelsPreparation_andDoesNotFinish() async {
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil, gender: nil))
        auth.profileSaveDelay = .seconds(30)
        let viewModel = makeViewModel(auth: auth)
        viewModel.chooseAIConsent(true)
        await waitUntil { auth.savedProfile != nil }

        auth.authState.send(.signedOut)
        await waitUntil { auth.profileSaveFinished }

        XCTAssertFalse(auth.showsMainScreen)
        XCTAssertFalse(viewModel.hasLoadingFailed)
        XCTAssertTrue(viewModel.onboardingRoutes.isEmpty)
        XCTAssertEqual(auth.aiConsentCount, 0)
        XCTAssertEqual(viewModel.alertMessage, "Сессия истекла. Войдите снова")
    }

}
