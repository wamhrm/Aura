//
//  HomeViewModelTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class HomeViewModelTests: AuraUnitTestCase {
    func test_refreshIfNeeded_doesNotRepeatTodaysInitialRequests() async {
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        await waitUntil { !viewModel.showsLoadingScreen }

        await viewModel.refreshIfNeeded()

        XCTAssertEqual(content.horoscopeCount, 1)
        XCTAssertEqual(content.insightCount, 1)
    }

    func test_confirmationCode_withSixLetters_sendsNothing() {
        let auth = MockAuthService()
        let viewModel = EmailConfirmationViewModel(authService: auth, email: "anna@mail.ru")
        viewModel.code = "abcdef"

        viewModel.confirm()

        XCTAssertTrue(viewModel.showAlert)
        XCTAssertNil(auth.confirmedCode)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_resendingConfirmationCode_usesTheSendingTitle() async {
        let viewModel = EmailConfirmationViewModel(authService: MockAuthService(), email: "anna@mail.ru")
        viewModel.sendCode()
        await waitUntil { viewModel.isCodeSent && !viewModel.isLoading }
        viewModel.code = "123456"
        viewModel.confirm()
        await waitUntil { !viewModel.isLoading }
        XCTAssertEqual(viewModel.loadingTitle, "Проверяем...")

        viewModel.sendCode()

        XCTAssertEqual(viewModel.loadingTitle, "Отправляем...")
        await waitUntil { !viewModel.isLoading }
    }

    func test_refresh_hidesOutdatedInsight_beforeRequestingNewContent() async {
        let content = MockContentService()
        content.dailyContentDate = "2000-01-01"
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        await waitUntil { viewModel.insightState == .loaded }
        content.dailyContentDate = todayText()
        var didClearInsight = false
        content.beforeContentResponse = {
            if viewModel.dailyInsight == nil { didClearInsight = true }
        }

        await viewModel.refresh()
        content.beforeContentResponse = nil

        XCTAssertTrue(didClearInsight)
        XCTAssertEqual(viewModel.dailyInsight?.isFromToday, true)
    }

    func test_birthDateChange_hidesPreviousHoroscope_whenReloadFails() async {
        let auth = MockAuthService(user: makeUser(dateOfBirth: "20.01.1990"))
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: auth, contentService: content)
        await waitUntil { viewModel.horoscopeState == .loaded }
        content.errorToThrow = serverError

        auth.authState.send(.signedIn(makeUser()))
        await waitUntil { viewModel.horoscopeState == .failed("Ошибка сервера") }

        XCTAssertNil(viewModel.horoscope)
    }

    func test_refreshFailure_keepsTheHoroscopeOnScreen() async {
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser(dateOfBirth: "20.01.1990")), contentService: content)
        await waitUntil { viewModel.horoscopeState == .loaded }
        content.errorToThrow = serverError

        await viewModel.refresh()

        XCTAssertEqual(viewModel.horoscope, .mock)
        XCTAssertEqual(viewModel.horoscopeState, .loaded)
    }

    // MARK: - Daily insight
    func test_homeStaysHidden_untilTheHoroscopeArrives() async {
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser(hasAIConsent: false)),
                                      contentService: MockContentService())

        XCTAssertTrue(viewModel.showsLoadingScreen)
        await waitUntil { !viewModel.showsLoadingScreen }

        XCTAssertNotNil(viewModel.horoscope)
    }

    func test_withoutConsent_theInsightIsNotRequested() async {
        // Given
        let content = MockContentService()

        // When
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser(hasAIConsent: false)),
                                      contentService: content)
        await waitUntil { viewModel.horoscopeState == .loaded }

        // Then
        XCTAssertEqual(viewModel.horoscopeState, .loaded)
        XCTAssertEqual(content.insightCount, 0)
    }

    func test_insightFailure_showsTheError_andNoText() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = serverError

        // When
        let viewModel = HomeViewModel(authService: MockAuthService(user: .mock), contentService: content)
        await waitUntil { viewModel.insightState == .failed("Ошибка сервера") }

        // Then
        XCTAssertEqual(viewModel.insightState, .failed("Ошибка сервера"))
        XCTAssertNil(viewModel.dailyInsight)
    }

    func test_refreshFailure_keepsTheInsightOnScreen() async {
        // Given
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: MockAuthService(user: .mock), contentService: content)
        await waitUntil { viewModel.insightState == .loaded }
        let insight = viewModel.dailyInsight
        content.errorToThrow = serverError

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.dailyInsight, insight)
        XCTAssertEqual(viewModel.insightState, .loaded)
    }

    // MARK: - Updates of the same user
    func test_givingConsent_loadsTheInsight_andNotTheHoroscopeAgain() async {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: auth, contentService: content)
        await waitUntil { viewModel.horoscopeState == .loaded }

        // When
        auth.authState.send(.signedIn(makeUser(hasAIConsent: true)))
        await waitUntil { viewModel.dailyInsight != nil }

        // Then
        XCTAssertNotNil(viewModel.dailyInsight)
        XCTAssertEqual(content.horoscopeCount, 1)
    }

    func test_newBirthDate_loadsTheHoroscope_andNotTheInsightAgain() async {
        // Given
        let auth = MockAuthService(user: makeUser())
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: auth, contentService: content)
        await waitUntil { viewModel.horoscopeState == .loaded && viewModel.insightState == .loaded }

        // When
        auth.authState.send(.signedIn(makeUser(dateOfBirth: "20.01.1990")))
        await waitUntil { content.horoscopeCount == 2 }

        // Then
        XCTAssertEqual(content.horoscopeCount, 2)
        XCTAssertEqual(content.insightCount, 1)
    }

    // MARK: - Email confirmation sheet
    func test_code_ofWrongLength_showsAlert_andSendsNothing() {
        // Given
        let auth = MockAuthService()
        let viewModel = EmailConfirmationViewModel(authService: auth, email: "anna@mail.ru")
        viewModel.code = "12345"

        // When
        viewModel.confirm()

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Код состоит из 6 цифр")
        XCTAssertNil(auth.confirmedCode)
    }

    func test_sendCode_whenCodeWasRecentlyRequested_opensTheCodeField() async {
        // Given
        let auth = MockAuthService()
        auth.errorToThrow = NetworkError.emailCodeRecentlyRequested("Код уже отправлен")
        let viewModel = EmailConfirmationViewModel(authService: auth, email: "anna@mail.ru")

        // When
        viewModel.sendCode()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Код уже отправлен")
        XCTAssertTrue(viewModel.isCodeSent)
    }

    func test_sendCode_whenTheServerFails_keepsTheCodeFieldClosed() async {
        // Given
        let auth = MockAuthService()
        auth.errorToThrow = serverError
        let viewModel = EmailConfirmationViewModel(authService: auth, email: "anna@mail.ru")

        // When
        viewModel.sendCode()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertFalse(viewModel.isCodeSent)
    }

    func test_personalityRetry_reusesTheRequestID_untilTheAnswersChange() async throws {
        // Given
        let content = MockContentService()
        content.errorToThrow = serverError
        let auth = MockAuthService(user: makeUser())
        let viewModel = HomeViewModel(authService: auth, contentService: content)

        // When the same selection is retried
        viewModel.makePersonalityTest()
        await waitUntil { content.personalityRequestIDs.count == 1 }
        viewModel.makePersonalityTest()
        await waitUntil { content.personalityRequestIDs.count == 2 }

        // Then
        let firstID = try XCTUnwrap(content.personalityRequestIDs.first)
        XCTAssertEqual(content.personalityRequestIDs, [firstID, firstID])

        // When the profile answer changes
        auth.authState.send(.signedIn(makeUser(socialType: "extrovert")))
        viewModel.makePersonalityTest()
        await waitUntil { content.personalityRequestIDs.count == 3 }

        // Then
        XCTAssertNotEqual(content.personalityRequestIDs.last, firstID)
    }

    func test_personalityRetry_usesANewRequestID_whenTheSelectedTestsChange() async throws {
        // Given
        let content = MockContentService()
        content.errorToThrow = serverError
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        viewModel.makePersonalityTest()
        await waitUntil { content.personalityRequestIDs.count == 1 }
        let firstID = try XCTUnwrap(content.personalityRequestIDs.first)

        // When
        viewModel.toggleTestSelection(.decisionMaking)
        viewModel.makePersonalityTest()
        await waitUntil { content.personalityRequestIDs.count == 2 }

        // Then
        XCTAssertNotEqual(content.personalityRequestIDs.last, firstID)
    }

    func test_showAIConsent_opensTheConsentScreen() {
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser(hasAIConsent: false)),
                                      contentService: MockContentService())

        viewModel.showAIConsent()

        XCTAssertEqual(viewModel.homeRoutes, [.aiConsent])
    }

    func test_allowAIConsent_loadsInsight_thenResetsTheRoutes() async {
        let content = MockContentService()
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let viewModel = HomeViewModel(authService: auth, contentService: content)
        await waitUntil { !viewModel.showsLoadingScreen }
        viewModel.showAIConsent()

        viewModel.allowAIConsent()
        await waitUntil { viewModel.homeRoutes.isEmpty && !viewModel.showsLoadingScreen }

        XCTAssertEqual(auth.aiConsentCount, 1)
        XCTAssertEqual(content.insightCount, 1)
        XCTAssertEqual(content.tipCount, 0)
    }

    func test_allowAIConsent_whenInsightFails_opensHomeAndAllowsRetry() async {
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: auth, contentService: content)
        await waitUntil { !viewModel.showsLoadingScreen }
        content.errorToThrow = serverError
        viewModel.showAIConsent()

        viewModel.allowAIConsent()
        await waitUntil { !viewModel.isLoading }

        XCTAssertTrue(viewModel.homeRoutes.isEmpty)
        XCTAssertTrue(viewModel.allowsAIAnalysis)
        XCTAssertEqual(viewModel.insightState, .failed("Ошибка сервера"))
        XCTAssertFalse(viewModel.showsLoadingScreen)
        XCTAssertFalse(viewModel.showAlert)
        XCTAssertEqual(content.insightCount, 1)

        content.errorToThrow = nil
        viewModel.retryDailyInsight()
        await waitUntil { viewModel.insightState == .loaded }

        XCTAssertNotNil(viewModel.dailyInsight)
        XCTAssertEqual(auth.aiConsentCount, 1)
        XCTAssertEqual(content.insightCount, 2)
    }

    func test_personalityResult_isVisibleWhileChangedBirthDateReloadsHoroscope() async {
        let auth = MockAuthService(user: makeUser())
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: auth, contentService: content)
        await waitUntil { !viewModel.showsLoadingScreen }
        content.horoscopeDelay = .seconds(2)

        viewModel.makePersonalityTest()
        auth.authState.send(.signedIn(makeUser(dateOfBirth: "20.01.1990")))
        await waitUntil { content.horoscopeCount == 2 }
        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.homeRoutes, [.testResults])
        XCTAssertNotNil(viewModel.personalityResult)
        XCTAssertEqual(viewModel.horoscopeState, .loading)
        XCTAssertFalse(viewModel.showsLoadingScreen)

        viewModel.homeRoutes = []
        XCTAssertTrue(viewModel.showsLoadingScreen)
        await waitUntil { !viewModel.showsLoadingScreen }
        XCTAssertEqual(viewModel.horoscopeState, .loaded)
    }

    func test_allowAIConsent_withPersonalityHistory_leavesTheTipToProfile() async {
        let content = MockContentService()
        content.historyCells.send([.personalityPlaceholder])
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser(hasAIConsent: false)),
                                      contentService: content)
        await waitUntil { !viewModel.showsLoadingScreen }
        viewModel.showAIConsent()

        viewModel.allowAIConsent()
        await waitUntil { viewModel.homeRoutes.isEmpty && !viewModel.showsLoadingScreen }

        XCTAssertEqual(content.insightCount, 1)
        XCTAssertEqual(content.tipCount, 0)
    }

    func test_failedInfoUpdate_staysOnTheConsentScreen() async {
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        auth.errorToThrow = serverError
        let viewModel = HomeViewModel(authService: auth, contentService: MockContentService())
        await waitUntil { !viewModel.showsLoadingScreen }
        viewModel.showAIConsent()

        viewModel.allowAIConsent()
        await waitUntil { viewModel.showAlert }

        XCTAssertEqual(viewModel.homeRoutes, [.aiConsent])
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
    }

    func test_declineAIConsent_resetsTheRoutes() async {
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser(hasAIConsent: false)),
                                      contentService: MockContentService())
        viewModel.showAIConsent()

        viewModel.declineAIConsent()

        XCTAssertTrue(viewModel.homeRoutes.isEmpty)
    }
}
