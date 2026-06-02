//
//  ContentServiceTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class ContentServiceTests: XCTestCase {
    func test_makePersonalityTest_emitsHistoryDidChange() async throws {
        // Given
        let sut = ContentService(networkService: MockNetworkService())
        let expectation = expectation(description: "historyDidChange")
        let cancellable = sut.historyDidChange.sink { expectation.fulfill() }

        // When
        _ = try await sut.makePersonalityTest(selectedTests: [.astrology])

        // Then
        await fulfillment(of: [expectation], timeout: 1)
        cancellable.cancel()
    }

    func test_makeCompatibilityTest_emitsHistoryDidChange() async throws {
        // Given
        let sut = ContentService(networkService: MockNetworkService())
        let expectation = expectation(description: "historyDidChange")
        let cancellable = sut.historyDidChange.sink { expectation.fulfill() }

        // When
        _ = try await sut.makeCompatibilityTest(request: PartnerInfoModel().compatibilityTestRequest(selectedTests: []))

        // Then
        await fulfillment(of: [expectation], timeout: 1)
        cancellable.cancel()
    }

    func test_deleteHistory_emitsHistoryDidChange() async throws {
        // Given
        let sut = ContentService(networkService: MockNetworkService())
        let expectation = expectation(description: "historyDidChange")
        let cancellable = sut.historyDidChange.sink { expectation.fulfill() }

        // When
        try await sut.deleteHistory(id: UUID())

        // Then
        await fulfillment(of: [expectation], timeout: 1)
        cancellable.cancel()
    }

    func test_fetchHistory_doesNotEmitHistoryDidChange() async throws {
        // Given
        let sut = ContentService(networkService: MockNetworkService())
        let expectation = expectation(description: "no emit")
        expectation.isInverted = true
        let cancellable = sut.historyDidChange.sink { expectation.fulfill() }

        // When
        _ = try await sut.fetchHistory()

        // Then
        await fulfillment(of: [expectation], timeout: 0.3)
        cancellable.cancel()
    }
}
