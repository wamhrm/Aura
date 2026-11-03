//
//  HomeViewModelTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class HomeViewModelTests: XCTestCase {
    // MARK: - Daily insight
    func test_withoutConsent_theInsightIsNotRequested() async {
        // Given
        let content = MockContentService()

        // When
        let viewModel = HomeViewModel(authService: MockAuthService(user: makeUser(hasAIConsent: false)),
                                      contentService: content,
                                      storage: makeStorage())
        await waitUntil { viewModel.horoscopeState == .loaded }

        // Then
        XCTAssertEqual(viewModel.horoscopeState, .loaded)
        XCTAssertEqual(content.insightCount, 0)
    }

    func test_savedInsightFromAnotherDay_isNotShown_whenTheServerFails() async {
        // Given
        let storage = makeStorage()
        storage.save(DailyContentModel(id: UUID(), text: "Вчерашний инсайт", dateCreated: "2000-01-01"),
                     for: StorageKeys.dailyInsight,
                     userId: UserModel.mock.id)
        let content = MockContentService()
        content.errorToThrow = serverError

        // When
        let viewModel = HomeViewModel(authService: MockAuthService(user: .mock), contentService: content, storage: storage)
        await waitUntil { viewModel.insightState == .failed("Ошибка сервера") }

        // Then
        XCTAssertEqual(viewModel.insightState, .failed("Ошибка сервера"))
        XCTAssertNil(viewModel.dailyInsight)
    }

    func test_savedInsightFromToday_stays_whenTheServerFails() async {
        // Given
        let insight = DailyContentModel(id: UUID(), text: "Сегодняшний инсайт", dateCreated: todayText())
        let storage = makeStorage()
        storage.save(insight, for: StorageKeys.dailyInsight, userId: UserModel.mock.id)
        let content = MockContentService()
        content.errorToThrow = serverError

        // When
        let viewModel = HomeViewModel(authService: MockAuthService(user: .mock), contentService: content, storage: storage)
        await waitUntil { content.insightCount == 1 }

        // Then
        XCTAssertEqual(viewModel.dailyInsight, insight)
    }

    // MARK: - Updates of the same user
    func test_givingConsent_loadsTheInsight_andNotTheHoroscopeAgain() async {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let content = MockContentService()
        let viewModel = HomeViewModel(authService: auth, contentService: content, storage: makeStorage())
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
        let viewModel = HomeViewModel(authService: auth, contentService: content, storage: makeStorage())
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
}
