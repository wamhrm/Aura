//
//  PersonalityService.swift
//  Aura
//
//  Created by ddorsat on 12.04.2026.
//


import Foundation
import Combine

protocol PsychologyServiceProtocol: AnyObject {
    var historyDidChange: PassthroughSubject<Void, Never> { get }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel
    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompabilityResultModel
    func fetchHistory() async throws -> [HistoryCellModel]
    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel
    func deleteHistory(id: UUID) async throws
}

final class PsychologyService: ObservableObject, PsychologyServiceProtocol {
    let historyDidChange = PassthroughSubject<Void, Never>()

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
