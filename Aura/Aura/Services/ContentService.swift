//
//  ContentService.swift
//  Aura
//
//  Created by wamhrm on 26.05.2026.
//

import Combine
import Foundation

protocol ContentServiceProtocol {
    var historyCells: CurrentValueSubject<[HistoryCellModel], Never> { get }
    var historyState: CurrentValueSubject<LoadState, Never> { get }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel
    func makeCompatibilityTest(request: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel
    func fetchHistory() async throws
    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel
    func deleteHistory(id: UUID) async throws
    func fetchDailyInsight() async throws -> DailyContentModel
    func fetchDailyTip() async throws -> DailyContentModel
    func fetchCurrentHoroscope() async throws -> HoroscopeModel
}

final class ContentService: ObservableObject, ContentServiceProtocol {
    let historyCells = CurrentValueSubject<[HistoryCellModel], Never>([])
    let historyState = CurrentValueSubject<LoadState, Never>(.loading)

    private let networkService: any NetworkServiceProtocol
    private let authService: any AuthServiceProtocol
    private var currentUserID: UUID?
    private var historyRequestID: UUID?
    private var cancellables = Set<AnyCancellable>()

    init(networkService: any NetworkServiceProtocol,
         authService: any AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService

        authService.authStatePublisher
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ authState: AuthState) {
        switch authState {
            case .signedIn(let user):
                if currentUserID != user.id {
                    clearHistory()
                }
                currentUserID = user.id
            case .signedOut:
                clearHistory()
                currentUserID = nil
        }
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        try await request { try await networkService.fetchDailyInsight() }
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        try await request { try await networkService.fetchDailyTip() }
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        try await request { try await networkService.fetchCurrentHoroscope() }
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes],
                             requestID: UUID) async throws -> PersonalityResultModel {
        let result = try await request {
            try await networkService.makePersonalityTest(selectedTests: selectedTests, requestID: requestID)
        }
        refreshHistory()
        return result
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest,
                               requestID: UUID) async throws -> CompatibilityResultModel {
        let result = try await self.request {
            try await networkService.makeCompatibilityTest(request, requestID: requestID)
        }
        refreshHistory()
        return result
    }

    func fetchHistory() async throws {
        let sessionID = authService.sessionID
        let requestID = UUID()
        historyRequestID = requestID
        if historyCells.value.isEmpty { historyState.send(.loading) }

        defer {
            if historyRequestID == requestID { historyRequestID = nil }
        }

        do {
            let history = try await request { try await networkService.fetchHistory() }
            guard sessionID == authService.sessionID else { throw NetworkError.cancelled }
            guard historyRequestID == requestID else { return }
            historyState.send(.loaded)
            historyCells.send(history)
        } catch {
            guard sessionID == authService.sessionID else { throw error }
            guard historyRequestID == requestID else { return }
            if historyCells.value.isEmpty {
                historyState.send(.failed(error.userMessage))
            }
            throw error
        }
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await request { try await networkService.fetchHistoryDetails(id: id) }
    }

    func deleteHistory(id: UUID) async throws {
        try await request { try await networkService.deleteHistory(id: id) }
        let wasFetchingHistory = historyRequestID != nil
        historyRequestID = nil
        historyState.send(.loaded)
        historyCells.send(historyCells.value.filter { $0.id != id })
        if wasFetchingHistory { refreshHistory() }
    }

    private func refreshHistory() {
        let sessionID = authService.sessionID
        Task {
            guard sessionID == authService.sessionID else { return }
            try? await fetchHistory()
        }
    }

    private func clearHistory() {
        historyRequestID = nil
        historyState.send(.loading)
        historyCells.send([])
    }

    private func request<T>(_ operation: () async throws -> T) async throws -> T {
        let sessionID = authService.sessionID

        do {
            let result = try await operation()
            guard sessionID == authService.sessionID else { throw NetworkError.cancelled }
            return result
        } catch NetworkError.sessionExpired {
            guard sessionID == authService.sessionID else { throw NetworkError.cancelled }
            authService.endExpiredSession()
            throw NetworkError.sessionExpired
        }
    }
}
