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
final class HomeViewModelTests: XCTestCase {
    func test_refresh_hidesOutdatedInsight_beforeRequestingNewContent() async {
        let content = MockContentService()
        content.dailyContentDate = "2000-01-01"
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        await waitUntil { viewModel.insightState == .loaded }
        content.dailyContentDate = todayText()
        content.beforeContentResponse = { XCTAssertNil(viewModel.dailyInsight) }

        await viewModel.refresh()
        content.beforeContentResponse = nil

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

    func test_sendCode_whenTheLimitIsReached_stillOpensTheCodeField() async {
        // Given
        let auth = MockAuthService()
        auth.errorToThrow = NetworkError.limited("Код уже отправлен")
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
}
