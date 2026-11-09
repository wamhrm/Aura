//
//  HistoryViewModelTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest
@testable import Aura

@MainActor
final class HistoryViewModelTests: XCTestCase {
    func test_fetch_showsTheServerList() async {
        // Given
        let content = MockContentService()
        content.history = [HistoryCellModel.personalityPlaceholder]

        // When
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content)
        await waitUntil { viewModel.historyCells.count == 1 }

        // Then
        XCTAssertEqual(viewModel.historyCells, content.history)
        XCTAssertEqual(viewModel.loadState, .loaded)
    }

    func test_serverFailure_withAnEmptyList_showsTheError() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = serverError

        // When
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content)
        await waitUntil { viewModel.loadState == .failed("Ошибка сервера") }

        // Then
        XCTAssertTrue(viewModel.historyCells.isEmpty)
        XCTAssertFalse(viewModel.showAlert)
    }

    func test_refreshFailure_keepsTheList_andShowsAlert() async {
        // Given
        let cell = HistoryCellModel.personalityPlaceholder
        let content = MockContentService()
        content.history = [cell]
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content)
        await waitUntil { viewModel.historyCells.count == 1 }
        content.errorToThrow = serverError

        // When
        await viewModel.fetchHistory()

        // Then
        XCTAssertEqual(viewModel.historyCells, [cell])
        XCTAssertEqual(viewModel.loadState, .loaded)
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
    }

    func test_delete_removesOnlyThatRecord() async {
        // Given
        let personality = HistoryCellModel.personalityPlaceholder
        let compatibility = HistoryCellModel.compatibilityPlaceholder
        let content = MockContentService()
        content.history = [personality, compatibility]
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content)
        await waitUntil { viewModel.historyCells.count == 2 }

        // When
        viewModel.requestDeletion(item: personality)
        viewModel.deleteRequestedCell()
        await waitUntil { viewModel.historyCells.count == 1 }

        // Then
        XCTAssertEqual(viewModel.historyCells, [compatibility])
    }

    func test_deleteFailure_keepsTheRecord_andShowsAlert() async {
        // Given
        let cell = HistoryCellModel.personalityPlaceholder
        let content = MockContentService()
        content.history = [cell]
        let viewModel = HistoryViewModel(authService: MockAuthService(user: .mock), contentService: content)
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
