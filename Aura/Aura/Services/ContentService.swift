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
    var refreshRequested: PassthroughSubject<Void, Never> { get }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel
    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompatibilityResultModel
    func fetchHistory() async throws -> [HistoryCellModel]
    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel
    func deleteHistory(id: UUID) async throws
    func fetchDailyInsight(for userId: UUID) async throws -> DailyContentModel
    func fetchDailyTip(for userId: UUID) async throws -> DailyContentModel
    func fetchCurrentHoroscope(for userId: UUID) async throws -> HoroscopeModel
}

final class ContentService: ObservableObject, ContentServiceProtocol {
    let historyDidChange = PassthroughSubject<Void, Never>()
    let refreshRequested = PassthroughSubject<Void, Never>()

    private let networkService: any NetworkServiceProtocol
    private let storage: any LocalStorageProtocol
    private var historyTask: Task<[HistoryCellModel], any Error>?
    private var pendingPersonalityTest: (tests: [PersonalityTestTypes], requestID: UUID)?
    private var pendingCompatibilityTest: (request: CompatibilityTestRequest, requestID: UUID)?
    private var currentUserId: UUID?
    private var cancellables = Set<AnyCancellable>()

    init(networkService: any NetworkServiceProtocol,
         authService: any AuthServiceProtocol,
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.networkService = networkService
        self.storage = storage

        authService.authState
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ authState: AuthState) {
        switch authState {
            case .signedIn(let user):
                if currentUserId != user.id {
                    resetSessionState()
                }
                currentUserId = user.id
            case .signedOut:
                resetSessionState()
                currentUserId = nil
        }
    }

    private func resetSessionState() {
        historyTask?.cancel()
        historyTask = nil
        pendingPersonalityTest = nil
        pendingCompatibilityTest = nil
    }

    func fetchDailyInsight(for userId: UUID) async throws -> DailyContentModel {
        let insight = try await networkService.fetchDailyInsight()
        saveToCache(insight, for: StorageKeys.dailyInsight, userId: userId)
        return insight
    }

    func fetchDailyTip(for userId: UUID) async throws -> DailyContentModel {
        let tip = try await networkService.fetchDailyTip()
        saveToCache(tip, for: StorageKeys.dailyTip, userId: userId)
        return tip
    }

    func fetchCurrentHoroscope(for userId: UUID) async throws -> HoroscopeModel {
        let horoscope = try await networkService.fetchCurrentHoroscope()
        saveToCache(horoscope, for: StorageKeys.horoscope, userId: userId)
        return horoscope
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        var requestID = UUID()

        // A repeat keeps its key: if the first answer was lost, the server returns the saved result
        if let pending = pendingPersonalityTest, pending.tests == selectedTests {
            requestID = pending.requestID
        }

        pendingPersonalityTest = (selectedTests, requestID)

        let result = try await networkService.makePersonalityTest(selectedTests: selectedTests, requestID: requestID)
        pendingPersonalityTest = nil
        notifyHistoryChanged()
        return result
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompatibilityResultModel {
        var requestID = UUID()

        // A repeat keeps its key: if the first answer was lost, the server returns the saved result
        if let pending = pendingCompatibilityTest, pending.request == request {
            requestID = pending.requestID
        }

        pendingCompatibilityTest = (request, requestID)

        let result = try await networkService.makeCompatibilityTest(request, requestID: requestID)
        pendingCompatibilityTest = nil
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

    // A late answer must not bring back the files of a finished session
    private func saveToCache<Value>(_ value: Value, for key: StorageKey<Value>, userId: UUID) {
        guard currentUserId == userId else { return }
        storage.save(value, for: key, userId: userId)
    }

    private func notifyHistoryChanged() {
        historyTask = nil
        historyDidChange.send(())
    }
}

extension ContentService {
    static let preview = ContentService(networkService: NetworkService(), authService: AuthService.preview)
}
