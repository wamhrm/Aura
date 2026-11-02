//
//  ProfileViewModelTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class ProfileViewModelTests: XCTestCase {
    // MARK: - signOut
    func test_signOut_callsAuthServiceAndHidesSettings() {
        // Given
        let (sut, auth) = makeSUT()
        sut.showSettings = true

        // When
        sut.signOut()

        // Then
        XCTAssertEqual(auth.signOutCallCount, 1)
        XCTAssertFalse(sut.showSettings)
    }

    // MARK: - Loading content
    func test_withoutTests_showsSampleTextOnlyForTheLockedScreen() async {
        // Given / When
        let (sut, _) = makeSUT(state: .signedIn(.mock))
        await waitUntil { sut.personalityState == .loaded }

        // Then
        XCTAssertFalse(sut.hasPersonalityTests)
        XCTAssertEqual(sut.profileDisplayHandler, .placeholder)
    }

    func test_withResult_showsOnlyWhatTheResultContains() async {
        // Given
        let content = MockContentService()
        var item = HistoryCellModel.personalityPlaceholder
        item = HistoryCellModel(id: item.id, kind: .personality, createdAt: item.createdAt, selectedTests: item.selectedTests,
                                archetypeTitle: item.archetypeTitle, archetypeSubtitle: item.archetypeSubtitle,
                                zodiacSign: item.zodiacSign, compatibilityScore: nil, partnerName: nil, partnerZodiacSign: nil,
                                personalityResult: .mock, compatibilityResult: nil)
        content.historyToReturn = [item]
        content.historyDetailsToReturn = item

        // When
        let (sut, _) = makeSUT(state: .signedIn(.mock), content: content)
        await waitUntil { sut.hasPersonalityTests && sut.tipState == .loaded }

        // Then
        let display = sut.profileDisplayHandler
        XCTAssertEqual(display.overview, PersonalityResultModel.mock.overview.description)
        XCTAssertNil(display.socialFilter)
        XCTAssertNil(display.emotionalDepth)
        XCTAssertEqual(display.dailyTip, MockContentService.dailyContent.text)
        XCTAssertEqual(display.zodiacSignTitle, "Водолей")
    }

    func test_whenLoadingFails_showsTheErrorInsteadOfAskingToTakeATest() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed

        // When
        let (sut, _) = makeSUT(state: .signedIn(.mock), content: content)
        await waitUntil { sut.personalityState != .loading && sut.tipState != .loading }

        // Then
        XCTAssertEqual(sut.personalityState, .failed("Что-то пошло не так. Попробуйте ещё раз"))
        XCTAssertEqual(sut.tipState, .failed("Что-то пошло не так. Попробуйте ещё раз"))
        XCTAssertFalse(sut.showAlert)
    }

    func test_retry_afterFailure_loadsTheContent() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed
        let (sut, _) = makeSUT(state: .signedIn(.mock), content: content)
        await waitUntil { sut.personalityState != .loading && sut.tipState != .loading }
        content.errorToThrow = nil

        // When
        sut.retryPersonality()
        sut.retryDailyTip()
        await waitUntil { sut.personalityState == .loaded && sut.tipState == .loaded }

        // Then
        XCTAssertNotNil(sut.dailyTip)
    }

    func test_sameUserUpdate_doesNotReloadContent() async {
        // Given
        let content = MockContentService()
        let (sut, auth) = makeSUT(state: .signedIn(.mock), content: content)
        await waitUntil { sut.personalityState == .loaded && sut.tipState == .loaded }

        // When
        auth.authState.send(.signedIn(.mock))
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertEqual(content.fetchHistoryCallCount, 1)
        XCTAssertEqual(content.fetchTipCallCount, 1)
    }

    func test_refreshRequest_reloadsContent() async {
        // Given
        let content = MockContentService()
        let (sut, _) = makeSUT(state: .signedIn(.mock), content: content)
        await waitUntil { sut.personalityState == .loaded && sut.tipState == .loaded }

        // When
        content.refreshRequested.send()
        await waitUntil { content.fetchHistoryCallCount == 2 && content.fetchTipCallCount == 2 }

        // Then
        XCTAssertEqual(content.fetchTipCallCount, 2)
    }

    // MARK: - Profile form
    func test_showAddProfileInfo_opensAFormFilledWithTheCurrentUser() async {
        // Given
        let (sut, _) = makeSUT(state: .signedIn(.mock))
        await waitUntil { sut.user != nil }

        // When
        sut.showAddProfileInfo()

        // Then
        XCTAssertEqual(sut.profileForm?.profileInfo.dateOfBirth, UserModel.mock.dateOfBirth)
        XCTAssertEqual(sut.profileRoutes, [.addProfileInfo])
    }

    func test_showAddProfileInfo_twice_dropsUnsavedChanges() async {
        // Given
        let (sut, _) = makeSUT(state: .signedIn(.mock))
        await waitUntil { sut.user != nil }
        sut.showAddProfileInfo()
        sut.profileForm?.profileInfo.gender = "woman"

        // When
        sut.showAddProfileInfo()

        // Then
        XCTAssertEqual(sut.profileForm?.profileInfo.gender, UserModel.mock.gender)
    }

    // MARK: - Helpers
    private func makeSUT(state: AuthState = .signedOut,
                         content: MockContentService = MockContentService())
        -> (sut: ProfileViewModel, auth: MockAuthService) {
        let auth = MockAuthService(state: state)
        let sut = ProfileViewModel(authService: auth, contentService: content, storage: MockLocalStorage())
        return (sut, auth)
    }
}
