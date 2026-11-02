//
//  OnboardingViewModelTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    // MARK: - signIn validation
    func test_signIn_whenFieldsEmpty_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = ""
        sut.password = ""

        // When
        sut.signIn()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Заполните почту и пароль")
    }

    func test_signIn_whenEmailInvalid_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = "bad-email"
        sut.password = "123456"

        // When
        sut.signIn()

        // Then
        XCTAssertEqual(sut.alertMessage, "Укажите корректный e-mail")
    }

    func test_signIn_whenPasswordTooShort_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = "a@b.com"
        sut.password = "123"

        // When
        sut.signIn()

        // Then
        XCTAssertEqual(sut.alertMessage, "Пароль должен быть не короче 6 символов")
    }

    // MARK: - sign up validation
    func test_continueFromEmail_whenEmailEmpty_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = ""

        // When
        sut.continueFromEmail()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Укажите почту")
    }

    func test_continueFromNameAndBirth_whenNameTooShort_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.name = "A"

        // When
        sut.continueFromNameAndBirth()

        // Then
        XCTAssertEqual(sut.alertMessage, "Имя должно содержать минимум 2 символа")
    }

    // MARK: - Routes
    func test_consent_goesStraightToLoading() async {
        // Given
        let auth = MockAuthService(state: .signedIn(makeIncompleteUser()))
        auth.updateProfileInfoResult = UpdateProfileInfoResponse(user: .mock, horoscope: .mock)
        let sut = makeSUT(auth: auth)

        // When
        sut.chooseAIConsent(false)

        // Then
        XCTAssertEqual(sut.onboardingRoutes.last, .loading)
        XCTAssertFalse(sut.onboardingRoutes.contains(.notifications))
    }

    func test_progress_doesNotCountTheHiddenNotificationsStep() {
        // Given / When / Then
        XCTAssertNil(OnboardingRoutes.notifications.progress)
        XCTAssertEqual(OnboardingRoutes.aiConsent.progress, 1)
    }

    func test_goBack_onLaterStep_returnsToThePreviousOne() async {
        // Given
        let sut = makeSUT()
        sut.onboardingRoutes = [.nameAndBirth, .email]

        // When
        sut.goBack()

        // Then
        XCTAssertEqual(sut.onboardingRoutes, [.nameAndBirth])
        XCTAssertFalse(sut.showSignOutAlert)
    }

    func test_goBack_onOnlyStepWithoutSession_returnsToWelcome() {
        // Given
        let sut = makeSUT()
        sut.onboardingRoutes = [.nameAndBirth]

        // When
        sut.goBack()

        // Then
        XCTAssertEqual(sut.onboardingRoutes, [])
        XCTAssertFalse(sut.showSignOutAlert)
    }

    func test_goBack_onOnlyStepOfSignedInUser_offersToSignOut() {
        // Given
        let sut = makeSUT(auth: MockAuthService(state: .signedIn(makeIncompleteUser())))
        XCTAssertEqual(sut.onboardingRoutes, [.nameAndBirth])

        // When
        sut.goBack()

        // Then
        XCTAssertTrue(sut.showSignOutAlert)
        XCTAssertEqual(sut.onboardingRoutes, [.nameAndBirth])
        XCTAssertTrue(sut.hidesSystemBackButton(on: .nameAndBirth))
    }

    func test_signOut_returnsToWelcomeWithoutAnAlert() async {
        // Given
        let auth = MockAuthService(state: .signedIn(makeIncompleteUser()))
        let sut = makeSUT(auth: auth)
        try? await Task.sleep(for: .milliseconds(50))

        // When
        sut.signOut()
        try? await Task.sleep(for: .milliseconds(50))

        // Then
        XCTAssertEqual(auth.signOutCallCount, 1)
        XCTAssertEqual(sut.onboardingRoutes, [])
        XCTAssertFalse(sut.showAlert)
    }

    func test_expiredSession_returnsToWelcomeWithAnAlert() async {
        // Given
        let auth = MockAuthService(state: .signedIn(makeIncompleteUser()))
        let sut = makeSUT(auth: auth)
        try? await Task.sleep(for: .milliseconds(50))
        sut.onboardingRoutes = [.nameAndBirth, .psychotype, .aiConsent, .loading]

        // When
        auth.authState.send(.signedOut)
        await waitUntil { sut.onboardingRoutes.isEmpty }

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Сессия истекла. Войдите снова")
        XCTAssertFalse(sut.hasLoadingFailed)
    }

    func test_signedOutUser_staysOnTheCurrentStepWithoutAnAlert() async {
        // Given
        let sut = makeSUT()
        sut.onboardingRoutes = [.nameAndBirth, .email]

        // When
        try? await Task.sleep(for: .milliseconds(50))

        // Then
        XCTAssertEqual(sut.onboardingRoutes, [.nameAndBirth, .email])
        XCTAssertFalse(sut.showAlert)
    }

    // MARK: - Helpers
    private func makeSUT(auth: MockAuthService = MockAuthService()) -> OnboardingViewModel {
        OnboardingViewModel(authService: auth,
                            contentService: MockContentService()) {}
    }
}
