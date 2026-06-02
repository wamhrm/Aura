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

    override func setUp() {
        super.setUp()
        UserDefaultsHelper.deleteLocalHistory(for: user.id)
    }

    override func tearDown() {
        UserDefaultsHelper.deleteLocalHistory(for: user.id)
        super.tearDown()
    }

    func test_whenSignedIn_loadsHistoryFromService() async {
        // Given
        let content = MockContentService()
        content.historyToReturn = [.personalityPlaceholder, .compatibilityPlaceholder]

        // When
        let (sut, _, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.historyCells.count == 2 }

        // Then
        XCTAssertEqual(sut.historyCells.count, 2)
        XCTAssertTrue(sut.isSignedIn)
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

    func test_whenSignedOut_clearsState() async {
        // Given
        let content = MockContentService()
        content.historyToReturn = [.personalityPlaceholder, .compatibilityPlaceholder]
        let (sut, auth, _) = makeSUT(authState: .signedIn(user), content: content)
        await waitUntil { sut.historyCells.count == 2 }

        // When
        auth.authState.send(.signedOut)
        await waitUntil { !sut.isSignedIn }

        // Then
        XCTAssertTrue(sut.historyCells.isEmpty)
        XCTAssertFalse(sut.isSignedIn)
    }
    
    // MARK: - Helpers
    private func makeSUT(authState: AuthState = .signedOut,
                         content: MockContentService)
        -> (sut: HistoryViewModel, auth: MockAuthService, content: MockContentService) {
        let auth = MockAuthService(state: authState)
        let sut = HistoryViewModel(authService: auth, contentService: content)
        return (sut, auth, content)
    }

    private func personalityItemWithResult() -> HistoryCellModel {
        HistoryCellModel(id: UUID(),
                         kind: .personality,
                         createdAt: "2026-01-01",
                         selectedTests: [],
                         archetypeTitle: "",
                         archetypeSubtitle: "",
                         zodiacSign: "",
                         personalityResult: .mock,
                         compatibilityResult: nil)
    }
}
