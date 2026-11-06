//
//  HistoryViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class HistoryViewModelTests: XCTestCase {
    func test_lateHistoryResponse_doesNotRestoreDeletedRecord_orItsCache() async throws {
        let cell = HistoryCellModel.personalityPlaceholder
        let network = MockNetworkService()
        network.history = [cell]
        let auth = MockAuthService(user: .mock)
        let storage = makeStorage()
        let content = ContentService(networkService: network, authService: auth, storage: storage)
        let viewModel = HistoryViewModel(authService: auth, contentService: content, storage: storage)
        await waitUntil { viewModel.historyCells == [cell] }

        network.beforeHistoryResponse = {
            network.beforeHistoryResponse = nil
            try await content.deleteHistory(id: cell.id)
            await viewModel.fetchHistory()
        }
        await viewModel.fetchHistory()

        XCTAssertTrue(viewModel.historyCells.isEmpty)
        XCTAssertEqual(storage.load(StorageKeys.history, userId: UserModel.mock.id), [])
        XCTAssertFalse(viewModel.showAlert)
    }

    func test_lateDetailsResponse_afterDeletion_isDiscarded() async throws {
        let cell = HistoryCellModel.personalityPlaceholder
        let network = MockNetworkService()
        let content = ContentService(networkService: network, authService: MockAuthService(user: .mock), storage: makeStorage())
        network.beforeHistoryResponse = {
            network.beforeHistoryResponse = nil
            try await content.deleteHistory(id: cell.id)
        }

        do {
            _ = try await content.fetchHistoryDetails(id: cell.id)
            XCTFail("Deleted history details must be discarded")
        } catch {
            XCTAssertTrue(error.isCancellation)
        }
    }

    func test_serverFailure_keepsTheSavedList_withoutAnError() async {
        // Given
        let cell = HistoryCellModel.personalityPlaceholder
        let storage = makeStorage()
        storage.save([cell], key: StorageKeys.history, userId: UserModel.mock.id)
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
        viewModel.requestDeletion(item: personality)
        viewModel.deleteRequestedCell()
        await waitUntil { viewModel.historyCells.count == 1 }

        // Then
        XCTAssertEqual(viewModel.historyCells, [compatibility])
        XCTAssertEqual(storage.load(StorageKeys.history, userId: UserModel.mock.id), [compatibility])
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
        viewModel.requestDeletion(item: cell)
        viewModel.deleteRequestedCell()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Не удалось удалить запись")
        XCTAssertEqual(viewModel.historyCells, [cell])
    }
}
