//
//  HistoryViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class HistoryViewModelTests: XCTestCase {
    func test_serverFailure_keepsTheSavedList_withoutAnError() async {
        // Given
        let cell = HistoryCellModel.personalityPlaceholder
        let storage = makeStorage()
        storage.save([cell], for: StorageKeys.history, userId: UserModel.mock.id)
        let content = MockContentService()
        content.errorToThrow = serverError

        // When
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content, storage: storage)
        await waitUntil { content.fetchHistoryCount == 1 }

        // Then
        XCTAssertEqual(viewModel.historyCells, [cell])
        XCTAssertEqual(viewModel.loadState, .loaded)
        XCTAssertFalse(viewModel.showAlert)
    }

    func test_delete_removesOnlyThatRecord_andUpdatesTheSavedList() async {
        // Given
        let personality = HistoryCellModel.personalityPlaceholder
        let compatibility = HistoryCellModel.compatibilityPlaceholder
        let storage = makeStorage()
        let content = MockContentService()
        content.history = [personality, compatibility]
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content, storage: storage)
        await waitUntil { viewModel.historyCells.count == 2 }

        // When
        viewModel.requestDeletion(of: personality)
        viewModel.deleteRequestedCell()
        await waitUntil { viewModel.historyCells.count == 1 }

        // Then
        XCTAssertEqual(viewModel.historyCells, [compatibility])
        XCTAssertEqual(storage.load(StorageKeys.history, for: UserModel.mock.id), [compatibility])
    }

    func test_deleteFailure_keepsTheRecord_andShowsAlert() async {
        // Given
        let cell = HistoryCellModel.personalityPlaceholder
        let content = MockContentService()
        content.history = [cell]
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content, storage: makeStorage())
        await waitUntil { viewModel.historyCells.count == 1 }
        content.errorToThrow = serverError

        // When
        viewModel.requestDeletion(of: cell)
        viewModel.deleteRequestedCell()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Не удалось удалить запись")
        XCTAssertEqual(viewModel.historyCells, [cell])
    }
}
