//
//  OnboardingViewModelTests.swift
//  AuraUnitTests
//

import SwiftUI
import XCTest
@testable import Aura

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    private func makeViewModel(auth: MockAuthService, onFinish: @escaping () -> Void = {}) -> OnboardingViewModel {
        OnboardingViewModel(authService: auth, contentService: MockContentService(), onFinish: onFinish)
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
        var didFinish = false
        let viewModel = makeViewModel(auth: auth) { didFinish = true }

        // When
        await signIn(viewModel)

        // Then
        XCTAssertTrue(didFinish)
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
    func test_returningUser_decliningConsent_finishesWithoutARequest() {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        var didFinish = false
        let viewModel = makeViewModel(auth: auth) { didFinish = true }

        // When
        viewModel.chooseAIConsent(false)

        // Then
        XCTAssertTrue(didFinish)
        XCTAssertEqual(auth.aiConsentCount, 0)
    }

    func test_returningUser_allowingConsent_savesIt_andFinishes() async {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        var didFinish = false
        let viewModel = makeViewModel(auth: auth) { didFinish = true }

        // When
        viewModel.chooseAIConsent(true)
        await waitUntil { didFinish }

        // Then
        XCTAssertEqual(auth.aiConsentCount, 1)
    }

    func test_newUser_decliningConsent_skipsTheInsightStage() {
        // Given
        let auth = MockAuthService(user: makeUser(dateOfBirth: nil, gender: nil))
        let viewModel = makeViewModel(auth: auth)

        // When
        viewModel.chooseAIConsent(false)

        // Then
        XCTAssertEqual(viewModel.loadingStages, [.profile, .horoscope])
    }

    // MARK: - Which screen the app opens
    func test_root_opensTheMainScreen_onlyWithACompleteProfile() {
        // Given
        let content = MockContentService()

        // When
        let complete = RootViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        let incomplete = RootViewModel(authService: MockAuthService(user: makeUser(dateOfBirth: nil)), contentService: content)
        let signedOut = RootViewModel(authService: MockAuthService(), contentService: content)

        // Then
        XCTAssertEqual(complete.screen, .main)
        XCTAssertEqual(incomplete.screen, .onboarding)
        XCTAssertEqual(signedOut.screen, .onboarding)
    }

    func test_root_refreshesTheUser_onlyAfterTheInterval() {
        // Given
        let auth = MockAuthService(user: makeUser())
        let content = MockContentService()
        let justOpened = RootViewModel(authService: auth, contentService: content)
        let openedLongAgo = RootViewModel(authService: auth, contentService: content, refreshInterval: 0)

        // When
        justOpened.handleScenePhase(.active)
        let refreshesBeforeTheInterval = auth.refreshUserCount
        openedLongAgo.handleScenePhase(.active)

        // Then
        XCTAssertEqual(refreshesBeforeTheInterval, 0)
        XCTAssertEqual(auth.refreshUserCount, 1)
    }
}
