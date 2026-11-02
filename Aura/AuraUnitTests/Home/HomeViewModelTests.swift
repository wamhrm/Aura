//
//  HomeViewModelTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class HomeViewModelTests: XCTestCase {
    // MARK: - Test selection
    func test_toggleTestSelection_whenRemovingBelowMinimum_showsAlertAndKeepsSelection() {
        // Given
        let (sut, _, _) = makeSUT()
        let initialSelection = sut.selectedTests
        let testToRemove = initialSelection[0]

        // When
        sut.toggleTestSelection(testToRemove)

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Нельзя выбрать меньше 2 тестов")
        XCTAssertEqual(sut.selectedTests, initialSelection)
    }

    func test_toggleTestSelection_addsUnselectedTest() throws {
        // Given
        let (sut, _, _) = makeSUT()
        let testToAdd = try XCTUnwrap(PersonalityTestTypes.allCases.first { !sut.selectedTests.contains($0) })

        // When
        sut.toggleTestSelection(testToAdd)

        // Then
        XCTAssertTrue(sut.selectedTests.contains(testToAdd))
    }

    func test_toggleTestSelection_removesWhenAboveMinimum() throws {
        // Given
        let (sut, _, _) = makeSUT()
        let extraTest = try XCTUnwrap(PersonalityTestTypes.allCases.first { !sut.selectedTests.contains($0) })
        sut.toggleTestSelection(extraTest)
        let testToRemove = sut.selectedTests[0]

        // When
        sut.toggleTestSelection(testToRemove)

        // Then
        XCTAssertFalse(sut.selectedTests.contains(testToRemove))
        XCTAssertEqual(sut.selectedTests.count, 2)
    }

    // MARK: - Personality test
    func test_makePersonalityTest_whenSucceeds_setsResultAndAppendsRoute() async {
        // Given
        let (sut, _, content) = makeSUT()

        // When
        sut.makePersonalityTest()
        await waitUntil { sut.personalityResult != nil }

        // Then
        XCTAssertEqual(content.makePersonalityTestCallCount, 1)
        XCTAssertTrue(sut.homeRoutes.contains(.testResults))
        XCTAssertFalse(sut.isLoading)
    }

    func test_makePersonalityTest_whenServiceFails_showsAlert() async {
        // Given
        let (sut, _, content) = makeSUT()
        content.errorToThrow = MockError.notStubbed

        // When
        sut.makePersonalityTest()
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Что-то пошло не так. Попробуйте ещё раз")
        XCTAssertFalse(sut.homeRoutes.contains(.testResults))
    }

    // MARK: - Loading content
    func test_signIn_loadsHoroscopeAndInsight() async {
        // Given / When
        let (sut, _, content) = makeSUT(authState: .signedIn(.mock))
        await waitUntil { sut.insightState == .loaded && sut.horoscopeState == .loaded }

        // Then
        XCTAssertNotNil(sut.horoscope)
        XCTAssertNotNil(sut.dailyInsight)
        XCTAssertEqual(content.fetchHoroscopeCallCount, 1)
        XCTAssertEqual(content.fetchInsightCallCount, 1)
    }

    func test_signIn_whenLoadingFails_showsTheErrorOnScreenAndInventsNothing() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed

        // When
        let (sut, _, _) = makeSUT(authState: .signedIn(.mock), content: content)
        await waitUntil { sut.insightState != .loading && sut.horoscopeState != .loading }

        // Then
        XCTAssertEqual(sut.insightState, .failed("Что-то пошло не так. Попробуйте ещё раз"))
        XCTAssertEqual(sut.horoscopeState, .failed("Что-то пошло не так. Попробуйте ещё раз"))
        XCTAssertNil(sut.dailyInsight)
        XCTAssertFalse(sut.showAlert)
    }

    func test_retry_afterFailure_loadsTheContent() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed
        let (sut, _, _) = makeSUT(authState: .signedIn(.mock), content: content)
        await waitUntil { sut.insightState != .loading && sut.horoscopeState != .loading }
        content.errorToThrow = nil

        // When
        sut.retryDailyInsight()
        sut.retryHoroscope()
        await waitUntil { sut.insightState == .loaded && sut.horoscopeState == .loaded }

        // Then
        XCTAssertNotNil(sut.dailyInsight)
        XCTAssertNotNil(sut.horoscope)
    }

    func test_cachedInsight_fromAnotherDay_isNotShown() async {
        // Given
        let storage = MockLocalStorage()
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed
        storage.save(DailyContentModel(id: UUID(), text: "Вчерашний инсайт", dateCreated: "2000-01-01"),
                     for: StorageKeys.dailyInsight,
                     userId: UserModel.mock.id)

        // When
        let (sut, _, _) = makeSUT(authState: .signedIn(.mock), content: content, storage: storage)
        await waitUntil { sut.insightState != .loading }

        // Then
        XCTAssertNil(sut.dailyInsight)
    }

    func test_withoutConsent_insightIsNotRequested() async {
        // Given / When
        let (sut, _, content) = makeSUT(authState: .signedIn(makeUser(hasAIConsent: false)))
        await waitUntil { sut.horoscopeState == .loaded }

        // Then
        XCTAssertEqual(content.fetchInsightCallCount, 0)
    }

    // MARK: - Updates of the same user
    func test_sameUserUpdate_doesNotReloadContent() async {
        // Given
        let (sut, auth, content) = makeSUT(authState: .signedIn(.mock))
        await waitUntil { sut.insightState == .loaded && sut.horoscopeState == .loaded }

        // When
        auth.authState.send(.signedIn(.mock))
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertEqual(content.fetchHoroscopeCallCount, 1)
        XCTAssertEqual(content.fetchInsightCallCount, 1)
    }

    func test_givenConsent_loadsOnlyTheInsight() async {
        // Given
        let (sut, auth, content) = makeSUT(authState: .signedIn(makeUser(hasAIConsent: false)))
        await waitUntil { sut.horoscopeState == .loaded }

        // When
        auth.authState.send(.signedIn(makeUser(hasAIConsent: true)))
        await waitUntil { sut.insightState == .loaded }

        // Then
        XCTAssertTrue(sut.allowsAIAnalysis)
        XCTAssertEqual(content.fetchInsightCallCount, 1)
        XCTAssertEqual(content.fetchHoroscopeCallCount, 1)
    }

    func test_newDateOfBirth_loadsOnlyTheHoroscope() async {
        // Given
        let (sut, auth, content) = makeSUT(authState: .signedIn(makeUser(hasAIConsent: true)))
        await waitUntil { sut.insightState == .loaded && sut.horoscopeState == .loaded }

        // When
        auth.authState.send(.signedIn(makeUser(hasAIConsent: true, dateOfBirth: "20.01.1990")))
        await waitUntil { content.fetchHoroscopeCallCount == 2 }

        // Then
        XCTAssertEqual(content.fetchInsightCallCount, 1)
    }

    func test_refreshRequest_reloadsContent() async {
        // Given
        let (sut, _, content) = makeSUT(authState: .signedIn(.mock))
        await waitUntil { sut.insightState == .loaded && sut.horoscopeState == .loaded }

        // When
        content.refreshRequested.send()
        await waitUntil { content.fetchHoroscopeCallCount == 2 && content.fetchInsightCallCount == 2 }

        // Then
        XCTAssertEqual(content.fetchHoroscopeCallCount, 2)
    }

    func test_signOut_stopsReactingToTheNextSession() async {
        // Given
        let (sut, auth, content) = makeSUT(authState: .signedIn(.mock))
        await waitUntil { sut.insightState == .loaded && sut.horoscopeState == .loaded }

        // When
        auth.authState.send(.signedOut)
        try? await Task.sleep(for: .milliseconds(50))
        auth.authState.send(.signedIn(makeIncompleteUser()))
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertEqual(content.fetchHoroscopeCallCount, 1)
    }

    // MARK: - Helpers
    private func makeSUT(authState: AuthState = .signedOut,
                         content: MockContentService = MockContentService(),
                         storage: MockLocalStorage = MockLocalStorage())
        -> (sut: HomeViewModel, auth: MockAuthService, content: MockContentService) {
        let auth = MockAuthService(state: authState)
        let sut = HomeViewModel(authService: auth, contentService: content, storage: storage)
        return (sut, auth, content)
    }

    private func makeUser(hasAIConsent: Bool, dateOfBirth: String = "13.05.2000") -> UserModel {
        let user = UserModel.mock

        return UserModel(id: user.id,
                         name: user.name,
                         email: user.email,
                         dateOfBirth: dateOfBirth,
                         birthTime: user.birthTime,
                         gender: user.gender,
                         socialType: user.socialType,
                         conflictStyle: user.conflictStyle,
                         emotionalCore: user.emotionalCore,
                         decisionStyle: user.decisionStyle,
                         coreFocus: user.coreFocus,
                         hasAIConsent: hasAIConsent)
    }
}
