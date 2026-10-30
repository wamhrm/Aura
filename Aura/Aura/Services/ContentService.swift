//
//  ContentService.swift
//  Aura
//
//  Created by wamhrm on 26.05.2026.
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
    func fetchDailyInsight(for userId: UUID) async throws -> DailyContentModel
    func fetchDailyTip(for userId: UUID) async throws -> DailyContentModel
    func fetchCurrentHoroscope(for userId: UUID) async throws -> HoroscopeModel
}

final class ContentService: ObservableObject, ContentServiceProtocol {
    let historyDidChange = PassthroughSubject<Void, Never>()

    private let networkService: any NetworkServiceProtocol
    private let storage: any LocalStorageProtocol
    private var historyTask: Task<[HistoryCellModel], any Error>?

    init(networkService: any NetworkServiceProtocol = NetworkService(),
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.networkService = networkService
        self.storage = storage
    }

    func fetchDailyInsight(for userId: UUID) async throws -> DailyContentModel {
        let insight = try await networkService.fetchDailyInsight()
        storage.save(insight, for: StorageKeys.dailyInsight, userId: userId)
        return insight
    }

    func fetchDailyTip(for userId: UUID) async throws -> DailyContentModel {
        let tip = try await networkService.fetchDailyTip()
        storage.save(tip, for: StorageKeys.dailyTip, userId: userId)
        return tip
    }

    func fetchCurrentHoroscope(for userId: UUID) async throws -> HoroscopeModel {
        let horoscope = try await networkService.fetchCurrentHoroscope()
        storage.save(horoscope, for: StorageKeys.horoscope, userId: userId)
        return horoscope
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        let result = try await networkService.makePersonalityTest(selectedTests: selectedTests)
        notifyHistoryChanged()
        return result
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompabilityResultModel {
        let result = try await networkService.makeCompatibilityTest(request)
        notifyHistoryChanged()
        return result
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        if let historyTask {
            return try await historyTask.value
        }

        let networkService = networkService
        let task = Task { try await networkService.fetchHistory() }
        historyTask = task

        defer {
            if historyTask == task {
                historyTask = nil
            }
        }

        return try await task.value
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await networkService.fetchHistoryDetails(id: id)
    }

    func deleteHistory(id: UUID) async throws {
        try await networkService.deleteHistory(id: id)
        notifyHistoryChanged()
    }

    private func notifyHistoryChanged() {
        historyTask = nil
        historyDidChange.send(())
    }
}
