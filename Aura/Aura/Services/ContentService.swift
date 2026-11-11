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
    var horoscope: CurrentValueSubject<HoroscopeModel?, Never> { get }
    var dailyInsight: CurrentValueSubject<DailyContentModel?, Never> { get }
    var dailyTip: CurrentValueSubject<DailyContentModel?, Never> { get }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel
    func makeCompatibilityTest(request: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel
    func fetchHistory() async throws -> [HistoryCellModel]
    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel
    func deleteHistory(id: UUID) async throws
    func fetchDailyInsight() async throws -> DailyContentModel
    func fetchDailyTip() async throws -> DailyContentModel
    func fetchCurrentHoroscope() async throws -> HoroscopeModel
}

final class ContentService: ObservableObject, ContentServiceProtocol {
    let historyCells = CurrentValueSubject<[HistoryCellModel], Never>([])
    let horoscope = CurrentValueSubject<HoroscopeModel?, Never>(nil)
    let dailyInsight = CurrentValueSubject<DailyContentModel?, Never>(nil)
    let dailyTip = CurrentValueSubject<DailyContentModel?, Never>(nil)

    private let networkService: any NetworkServiceProtocol
    private let authService: any AuthServiceProtocol
    private var currentUser: UserModel?
    private var cancellables = Set<AnyCancellable>()

    init(networkService: any NetworkServiceProtocol,
         authService: any AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService

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
                if currentUser?.id != user.id {
                    clearContent()
                }
                currentUser = user
            case .signedOut:
                clearContent()
                currentUser = nil
        }
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        let insight = try await request { try await networkService.fetchDailyInsight() }
        dailyInsight.send(insight)
        return insight
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        let tip = try await request { try await networkService.fetchDailyTip() }
        dailyTip.send(tip)
        return tip
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        let horoscope = try await request { try await networkService.fetchCurrentHoroscope() }
        self.horoscope.send(horoscope)
        return horoscope
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes],
                             requestID: UUID) async throws -> PersonalityResultModel {
        let result = try await request {
            try await networkService.makePersonalityTest(selectedTests: selectedTests, requestID: requestID)
        }
        await reloadHistory()
        return result
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest,
                               requestID: UUID) async throws -> CompatibilityResultModel {
        let result = try await self.request {
            try await networkService.makeCompatibilityTest(request, requestID: requestID)
        }
        await reloadHistory()
        return result
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        let history = try await request { try await networkService.fetchHistory() }
        historyCells.send(history)
        return history
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await request { try await networkService.fetchHistoryDetails(id: id) }
    }

    func deleteHistory(id: UUID) async throws {
        try await request { try await networkService.deleteHistory(id: id) }
        historyCells.send(historyCells.value.filter { $0.id != id })
    }

    private func reloadHistory() async {
        guard let history = try? await request({ try await networkService.fetchHistory() }) else { return }
        historyCells.send(history)
    }
    
    private func clearContent() {
        historyCells.send([])
        horoscope.send(nil)
        dailyInsight.send(nil)
        dailyTip.send(nil)
    }

    private func request<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch NetworkError.sessionExpired {
            authService.endExpiredSession()
            throw NetworkError.sessionExpired
        }
    }
}

extension ContentService {
    static let preview = ContentService(networkService: NetworkService(), authService: AuthService.preview)
}
