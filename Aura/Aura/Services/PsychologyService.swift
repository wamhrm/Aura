//
//  PersonalityService.swift
//  Aura
//
//  Created by ddorsat on 12.04.2026.
//


import Foundation
import Combine

protocol PsychologyServiceProtocol: AnyObject {
    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel
    func makeCompatibilityTest(selectedTests: [PersonalityTestTypes]) async throws -> CompabilityResultModel
    func fetchPersonalityTests() async throws -> [HistoryCellModel]
    func fetchPersonalityTestDetails(id: UUID) async throws -> HistoryCellDetailsModel
}

final class PsychologyService: ObservableObject, PsychologyServiceProtocol {
    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        try await NetworkHelper.makePersonalityTest(selectedTests: selectedTests)
    }
    
    func makeCompatibilityTest(selectedTests: [PersonalityTestTypes]) async throws -> CompabilityResultModel {
        return CompabilityResultModel()
    }

    func fetchPersonalityTests() async throws -> [HistoryCellModel] {
        try await NetworkHelper.fetchPersonalityTests()
    }

    func fetchPersonalityTestDetails(id: UUID) async throws -> HistoryCellDetailsModel {
        try await NetworkHelper.fetchPersonalityTestDetails(id: id)
    }
}
