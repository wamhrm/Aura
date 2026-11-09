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

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel
    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompatibilityResultModel
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
    private var pendingPersonalityTest: (tests: [PersonalityTestTypes], requestID: UUID)?
    private var pendingCompatibilityTest: (request: CompatibilityTestRequest, requestID: UUID)?
    private var currentUser: UserModel?
    private var cancellables = Set<AnyCancellable>()

    init(networkService: any NetworkServiceProtocol,
         authService: any AuthServiceProtocol) {
        self.networkService = networkService

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
                } else if currentUser?.name != user.name || currentUser?.profileInfo != user.profileInfo {
                    // Both tests use the user's profile; edited input starts a new generation.
                    pendingPersonalityTest = nil
                    pendingCompatibilityTest = nil
                }
                currentUser = user
            case .signedOut:
                clearContent()
                currentUser = nil
        }
    }

    private func clearContent() {
        pendingPersonalityTest = nil
        pendingCompatibilityTest = nil
        historyCells.send([])
        horoscope.send(nil)
        dailyInsight.send(nil)
        dailyTip.send(nil)
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        let insight = try await networkService.fetchDailyInsight()
        dailyInsight.send(insight)
        return insight
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        let tip = try await networkService.fetchDailyTip()
        dailyTip.send(tip)
        return tip
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        let horoscope = try await networkService.fetchCurrentHoroscope()
        self.horoscope.send(horoscope)
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
        if pendingPersonalityTest?.requestID == requestID {
            pendingPersonalityTest = nil
        }
        await reloadHistory()
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
        if pendingCompatibilityTest?.requestID == requestID {
            pendingCompatibilityTest = nil
        }
        await reloadHistory()
        return result
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        let history = try await networkService.fetchHistory()
        historyCells.send(history)
        return history
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await networkService.fetchHistoryDetails(id: id)
    }

    func deleteHistory(id: UUID) async throws {
        try await networkService.deleteHistory(id: id)
        historyCells.send(historyCells.value.filter { $0.id != id })
    }

    private func reloadHistory() async {
        guard let history = try? await networkService.fetchHistory() else { return }
        historyCells.send(history)
    }
}

extension ContentService {
    static let preview = ContentService(networkService: NetworkService(), authService: AuthService.preview)
}
