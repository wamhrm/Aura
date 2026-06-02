//
//  MockContentService.swift
//  AuraUnitTests
//

import Combine
import Foundation
@testable import Aura

@MainActor
final class MockContentService: ContentServiceProtocol {
    let historyDidChange = PassthroughSubject<Void, Never>()

    var personalityResultToReturn = PersonalityResultModel.mock
    var compatibilityResultToReturn = CompabilityResultModel.mock
    var historyToReturn: [HistoryCellModel] = []
    var historyDetailsToReturn: HistoryCellModel = .compatibilityPlaceholder
    var errorToThrow: Error?

    private(set) var makePersonalityTestCallCount = 0
    private(set) var makeCompatibilityTestCallCount = 0
    private(set) var deleteHistoryCallCount = 0

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        makePersonalityTestCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return personalityResultToReturn
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompabilityResultModel {
        makeCompatibilityTestCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return compatibilityResultToReturn
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        if let errorToThrow { throw errorToThrow }
        return historyToReturn
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        if let errorToThrow { throw errorToThrow }
        return historyDetailsToReturn
    }

    func deleteHistory(id: UUID) async throws {
        deleteHistoryCallCount += 1
        if let errorToThrow { throw errorToThrow }
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        if let errorToThrow { throw errorToThrow }
        return Self.dailyContent
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        if let errorToThrow { throw errorToThrow }
        return Self.dailyContent
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    static let dailyContent = DailyContentModel(id: UUID(), text: "tip", dateCreated: "2026-01-01")
}
