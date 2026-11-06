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
    func fetchDailyInsight() async throws -> DailyContentModel
    func fetchDailyTip() async throws -> DailyContentModel
    func fetchCurrentHoroscope() async throws -> HoroscopeModel
}

final class ContentService: ObservableObject, ContentServiceProtocol {
    let historyDidChange = PassthroughSubject<Void, Never>()
    let refreshRequested = PassthroughSubject<Void, Never>()

    private let networkService: any NetworkServiceProtocol
    private var historyTask: Task<[HistoryCellModel], any Error>?
    private var historyRevision = 0
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
                    resetSessionState()
                } else if currentUser?.name != user.name || currentUser?.profileInfo != user.profileInfo {
                    // Both tests use the user's profile; edited input starts a new generation.
                    pendingPersonalityTest = nil
                    pendingCompatibilityTest = nil
                }
                currentUser = user
            case .signedOut:
                resetSessionState()
                currentUser = nil
        }
    }

    private func resetSessionState() {
        historyRevision += 1
        historyTask?.cancel()
        historyTask = nil
        pendingPersonalityTest = nil
        pendingCompatibilityTest = nil
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        try await networkService.fetchDailyInsight()
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        try await networkService.fetchDailyTip()
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        try await networkService.fetchCurrentHoroscope()
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
        if pendingCompatibilityTest?.requestID == requestID {
            pendingCompatibilityTest = nil
        }
        notifyHistoryChanged()
        return result
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        let revision = historyRevision
        let task: Task<[HistoryCellModel], any Error>

        if let historyTask {
            task = historyTask
        } else {
            let networkService = networkService
            task = Task { try await networkService.fetchHistory() }
            historyTask = task
        }

        defer {
            if historyTask == task {
                historyTask = nil
            }
        }

        let history = try await task.value
        guard revision == historyRevision else { throw CancellationError() }
        return history
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        let revision = historyRevision
        let details = try await networkService.fetchHistoryDetails(id: id)
        guard revision == historyRevision else { throw CancellationError() }
        return details
    }

    func deleteHistory(id: UUID) async throws {
        try await networkService.deleteHistory(id: id)
        notifyHistoryChanged()
    }

    private func notifyHistoryChanged() {
        // Readers that started before this change must not publish their old response.
        historyRevision += 1
        historyTask?.cancel()
        historyTask = nil
        historyDidChange.send(())
    }
}

extension ContentService {
    static let preview = ContentService(networkService: NetworkService(), authService: AuthService.preview)
}
