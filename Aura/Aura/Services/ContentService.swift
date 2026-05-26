//
//  ContentService.swift
//  Aura
//
//  Created by ddorsat on 26.05.2026.
//

import Combine
import Foundation

protocol ContentServiceProtocol {
    var historyDidChange: PassthroughSubject<Void, Never> { get }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel
    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompabilityResultModel
    func fetchHistory() async throws -> [HistoryCellModel]
    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel
    func deleteHistory(id: UUID) async throws
    func fetchDailyInsight() async throws -> DailyContentModel
    func fetchDailyTip() async throws -> DailyContentModel
    func fetchCurrentHoroscope() async throws -> HoroscopeModel
}

final class ContentService: ObservableObject, ContentServiceProtocol {
    let historyDidChange = PassthroughSubject<Void, Never>()
    
    func fetchDailyInsight() async throws -> DailyContentModel {
        try await NetworkService.fetchDailyInsight()
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        try await NetworkService.fetchDailyTip()
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        try await NetworkService.fetchCurrentHoroscope()
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        let result = try await NetworkService.makePersonalityTest(selectedTests: selectedTests)
        historyDidChange.send(())
        return result
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompabilityResultModel {
        let result = try await NetworkService.makeCompatibilityTest(request)
        historyDidChange.send(())
        return result
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        try await NetworkService.fetchHistory()
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await NetworkService.fetchHistoryDetails(id: id)
    }

    func deleteHistory(id: UUID) async throws {
        try await NetworkService.deleteHistory(id: id)
        historyDidChange.send(())
    }
}
