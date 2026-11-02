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
        let sut = ContentService(networkService: MockNetworkService(), authService: MockAuthService())
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
        let sut = ContentService(networkService: MockNetworkService(), authService: MockAuthService())
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
        let sut = ContentService(networkService: MockNetworkService(), authService: MockAuthService())
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
        let sut = ContentService(networkService: MockNetworkService(), authService: MockAuthService())
        let expectation = expectation(description: "no emit")
        expectation.isInverted = true
        let cancellable = sut.historyDidChange.sink { expectation.fulfill() }

        // When
        _ = try await sut.fetchHistory()

        // Then
        await fulfillment(of: [expectation], timeout: 0.3)
        cancellable.cancel()
    }

    // MARK: - Test keys
    func test_personalityTest_keepsTheKeyOnRepeatAndChangesItAfterSuccessOrNewSelection() async throws {
        // Given
        let network = MockNetworkService()
        let sut = ContentService(networkService: network, authService: MockAuthService())
        network.errorToThrow = MockError.notStubbed

        // When
        _ = try? await sut.makePersonalityTest(selectedTests: [.astrology, .loveLanguage])
        _ = try? await sut.makePersonalityTest(selectedTests: [.astrology, .loveLanguage])
        network.errorToThrow = nil
        _ = try await sut.makePersonalityTest(selectedTests: [.astrology, .loveLanguage])
        _ = try await sut.makePersonalityTest(selectedTests: [.astrology, .loveLanguage])
        network.errorToThrow = MockError.notStubbed
        _ = try? await sut.makePersonalityTest(selectedTests: [.astrology, .idealPartner])
        _ = try? await sut.makePersonalityTest(selectedTests: [.astrology, .decisionMaking])

        // Then
        let ids = network.sentRequestIDs
        XCTAssertEqual(ids.count, 6)
        XCTAssertEqual(ids[0], ids[1])
        XCTAssertEqual(ids[1], ids[2])
        XCTAssertEqual(Set(ids).count, 4)
    }

    func test_compatibilityTest_keepsTheKeyOnRepeatAndChangesItAfterSuccessOrNewRequest() async throws {
        // Given
        let network = MockNetworkService()
        let sut = ContentService(networkService: network, authService: MockAuthService())
        var info = PartnerInfoModel()
        info.name = "Анна"
        let first = info.compatibilityTestRequest(selectedTests: [.astrology, .loveLanguages, .conflictResolution])
        info.name = "Ольга"
        let second = info.compatibilityTestRequest(selectedTests: [.astrology, .loveLanguages, .conflictResolution])
        network.errorToThrow = MockError.notStubbed

        // When
        _ = try? await sut.makeCompatibilityTest(request: first)
        _ = try? await sut.makeCompatibilityTest(request: first)
        _ = try? await sut.makeCompatibilityTest(request: second)
        network.errorToThrow = nil
        _ = try await sut.makeCompatibilityTest(request: second)
        _ = try await sut.makeCompatibilityTest(request: second)

        // Then
        let ids = network.sentRequestIDs
        XCTAssertEqual(ids[0], ids[1])
        XCTAssertNotEqual(ids[1], ids[2])
        XCTAssertEqual(ids[2], ids[3])
        XCTAssertNotEqual(ids[3], ids[4])
    }

    func test_signOut_forgetsThePendingKey() async throws {
        // Given
        let network = MockNetworkService()
        let auth = MockAuthService(state: .signedIn(.mock))
        let sut = ContentService(networkService: network, authService: auth)
        network.errorToThrow = MockError.notStubbed
        _ = try? await sut.makePersonalityTest(selectedTests: [.astrology, .loveLanguage])

        // When
        auth.authState.send(.signedOut)
        _ = try? await sut.makePersonalityTest(selectedTests: [.astrology, .loveLanguage])

        // Then
        XCTAssertNotEqual(network.sentRequestIDs[0], network.sentRequestIDs[1])
    }

    // MARK: - Separate sessions
    func test_fetchHistory_ofNewAccount_doesNotJoinTheRequestOfThePreviousOne() async throws {
        // Given
        let network = MockNetworkService()
        let auth = MockAuthService(state: .signedIn(.mock))
        let sut = ContentService(networkService: network, authService: auth)
        network.historyToReturn = [.personalityPlaceholder]
        network.historyDelay = .seconds(5)
        let firstRequest = Task { try await sut.fetchHistory() }
        await waitUntil { network.fetchHistoryCallCount == 1 }

        // When
        auth.authState.send(.signedOut)
        auth.authState.send(.signedIn(makeIncompleteUser()))
        network.historyToReturn = []
        network.historyDelay = nil
        let history = try await sut.fetchHistory()

        // Then
        XCTAssertEqual(history, [])
        XCTAssertEqual(network.fetchHistoryCallCount, 2)
        firstRequest.cancel()
    }

    func test_lateAnswer_ofFinishedSession_isNotSavedToCache() async throws {
        // Given
        let storage = MockLocalStorage()
        let auth = MockAuthService(state: .signedIn(.mock))
        let sut = ContentService(networkService: MockNetworkService(), authService: auth, storage: storage)

        // When
        _ = try await sut.fetchDailyInsight(for: UUID())
        let afterForeignUser = storage.storedValuesCount
        _ = try await sut.fetchDailyInsight(for: UserModel.mock.id)
        let afterCurrentUser = storage.storedValuesCount

        // Then
        XCTAssertEqual(afterForeignUser, 0)
        XCTAssertEqual(afterCurrentUser, 1)
    }
}
