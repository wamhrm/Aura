//
//  HistoryViewModelTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class HistoryViewModelTests: XCTestCase {
    private let user = UserModel.mock

    func test_whenSignedIn_loadsHistoryFromService() async {
        // Given
        let content = MockContentService()
        content.historyToReturn = [.personalityPlaceholder, .compatibilityPlaceholder]

        // When
        let (sut, _, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.historyCells.count == 2 }

        // Then
        XCTAssertEqual(sut.historyCells.count, 2)
    }

    func test_emptyHistory_isNotAnError() async {
        // Given / When
        let (sut, _, _) = makeSUT(authState: .signedIn(user), content: MockContentService())
        await waitUntil { sut.loadState == .loaded }

        // Then
        XCTAssertEqual(sut.historyCells, [])
    }

    func test_whenLoadingFails_showsTheErrorOnScreenInsteadOfEmptyList() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed

        // When
        let (sut, _, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.loadState != .loading }

        // Then
        XCTAssertEqual(sut.loadState, .failed("Что-то пошло не так. Попробуйте ещё раз"))
        XCTAssertFalse(sut.showAlert)
    }

    func test_retry_afterFailure_loadsTheList() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed
        let (sut, _, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.loadState != .loading }
        content.errorToThrow = nil
        content.historyToReturn = [.personalityPlaceholder]

        // When
        sut.retry()
        await waitUntil { sut.loadState == .loaded }

        // Then
        XCTAssertEqual(sut.historyCells.count, 1)
    }

    func test_whenRefreshFails_keepsTheSavedListAndStaysSilent() async {
        // Given
        let storage = MockLocalStorage()
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed
        storage.save([.personalityPlaceholder], for: StorageKeys.history, userId: user.id)

        // When
        let auth = MockAuthService(state: .signedIn(user))
        let sut = HistoryViewModel(authService: auth, contentService: content, storage: storage)
        await waitUntil { content.fetchHistoryCallCount == 1 && !sut.historyCells.isEmpty }
        try? await Task.sleep(for: .milliseconds(50))

        // Then
        XCTAssertEqual(sut.loadState, .loaded)
        XCTAssertEqual(sut.historyCells.count, 1)
        XCTAssertFalse(sut.showAlert)
    }

    func test_pullToRefresh_whenFails_showsAlertAndKeepsTheList() async {
        // Given
        let content = MockContentService()
        content.historyToReturn = [.personalityPlaceholder]
        let (sut, _, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.historyCells.count == 1 }
        content.errorToThrow = MockError.notStubbed

        // When
        await sut.fetchHistory()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.historyCells.count, 1)
    }

    func test_sameUserUpdate_doesNotReloadTheList() async {
        // Given
        let content = MockContentService()
        let (sut, auth, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.loadState == .loaded }

        // When
        auth.authState.send(.signedIn(user))
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertEqual(content.fetchHistoryCallCount, 1)
    }

    func test_afterSignOut_ignoresTheNextSessionAndWritesNothing() async {
        // Given
        let storage = MockLocalStorage()
        let content = MockContentService()
        let auth = MockAuthService(state: .signedIn(user))
        let sut = HistoryViewModel(authService: auth, contentService: content, storage: storage)
        await waitUntil { sut.loadState == .loaded }
        let storedValues = storage.storedValuesCount

        // When
        auth.authState.send(.signedOut)
        try? await Task.sleep(for: .milliseconds(50))
        auth.authState.send(.signedIn(makeIncompleteUser()))
        content.refreshRequested.send()
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertEqual(content.fetchHistoryCallCount, 1)
        XCTAssertEqual(storage.storedValuesCount, storedValues)
    }

    func test_deleteHistoryCell_removesItemFromList() async {
        // Given
        let itemA = HistoryCellModel.personalityPlaceholder
        let itemB = HistoryCellModel.compatibilityPlaceholder
        let content = MockContentService()
        content.historyToReturn = [itemA, itemB]
        let (sut, _, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.historyCells.count == 2 }

        // When
        sut.deleteHistoryCell(itemA)
        await waitUntil { !sut.historyCells.contains(itemA) }

        // Then
        XCTAssertEqual(sut.historyCells, [itemB])
        XCTAssertEqual(content.deleteHistoryCallCount, 1)
    }

    func test_openHistoryCellDetails_whenPersonality_appendsPersonalityRoute() async {
        // Given
        let content = MockContentService()
        content.historyDetailsToReturn = personalityItemWithResult()
        let (sut, _, _) = makeSUT(content: content)

        // When
        sut.openHistoryCellDetails(.personalityPlaceholder)
        await waitUntil { !sut.historyRoutes.isEmpty }

        // Then
        guard let route = sut.historyRoutes.first, case .personalityResult = route else {
            return XCTFail("Ожидался personalityResult route")
        }
    }

    func test_openHistoryCellDetails_whenCompatibility_appendsCompatibilityRoute() async {
        // Given
        let content = MockContentService()
        content.historyDetailsToReturn = .compatibilityPlaceholder
        let (sut, _, _) = makeSUT(content: content)

        // When
        sut.openHistoryCellDetails(.compatibilityPlaceholder)
        await waitUntil { !sut.historyRoutes.isEmpty }

        // Then
        guard let route = sut.historyRoutes.first, case .compatibilityResult = route else {
            return XCTFail("Ожидался compatibilityResult route")
        }
    }

    func test_openHistoryCellDetails_whenServiceFails_showsAlert() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = MockError.notStubbed
        let (sut, _, _) = makeSUT(content: content)

        // When
        sut.openHistoryCellDetails(.personalityPlaceholder)
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Не удалось открыть результат")
    }

    // MARK: - Helpers
    private func makeSUT(authState: AuthState = .signedOut,
                         content: MockContentService)
        -> (sut: HistoryViewModel, auth: MockAuthService, content: MockContentService) {
        let auth = MockAuthService(state: authState)
        let sut = HistoryViewModel(authService: auth, contentService: content, storage: MockLocalStorage())
        return (sut, auth, content)
    }

    private func personalityItemWithResult() -> HistoryCellModel {
        HistoryCellModel(id: UUID(),
                         kind: .personality,
                         createdAt: "2026-01-01",
                         selectedTests: [],
                         archetypeTitle: "",
                         archetypeSubtitle: "",
                         zodiacSign: .aquarius,
                         compatibilityScore: nil,
                         partnerName: nil,
                         partnerZodiacSign: nil,
                         personalityResult: .mock,
                         compatibilityResult: nil)
    }
}
