//
//  HistoryViewModel.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Combine
import Foundation

enum HistoryRoutes: Hashable {
    case personalityResult(PersonalityResultModel)
    case compatibilityResult(CompatibilityResultModel)
}

@MainActor
final class HistoryViewModel: ObservableObject, AlertPresentable {
    @Published var historyRoutes: [HistoryRoutes] = []

    @Published private(set) var historyCells: [HistoryCellModel] = []
    @Published private(set) var loadState = LoadState.loading

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showDeleteAlert = false
    @Published private(set) var loadingTitle: String?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var currentUserId: UUID?
    private var cellToDelete: HistoryCellModel?
    private var coverTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private static let historyLoadTitle = "Загружаем историю"

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService
        self.historyCells = contentService.historyCells.value
        if historyCells.isEmpty {
            loadingTitle = Self.historyLoadTitle
        }

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
            }
            .store(in: &cancellables)

        contentService.historyCells
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cells in
                guard let self else { return }
                historyCells = cells
                if !cells.isEmpty { loadState = .loaded }
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ authState: AuthState) {
        switch authState {
            case .signedIn(let user):
                handleUser(user)
            case .signedOut:
                guard currentUserId != nil else { return }
                currentUserId = nil
                cancellables.removeAll()
        }
    }

    private func handleUser(_ user: UserModel) {
        guard currentUserId != user.id else { return }

        currentUserId = user.id
        Task { await fetchHistory() }
    }

    func fetchHistory() async {
        guard currentUserId != nil else { return }
        if historyCells.isEmpty {
            loadState = .loading
            if coverTask == nil { loadingTitle = Self.historyLoadTitle }
        }

        do {
            historyCells = try await contentService.fetchHistory()
            loadState = .loaded
        } catch {
            if historyCells.isEmpty {
                loadState = .failed(error.userMessage)
            } else {
                presentAlert(error.userMessage)
            }
        }

        if coverTask == nil { loadingTitle = nil }
    }

    func retry() {
        Task { await fetchHistory() }
    }

    func requestDeletion(item: HistoryCellModel) {
        cellToDelete = item
        showDeleteAlert = true
    }

    func deleteRequestedCell() {
        guard let item = cellToDelete else { return }

        cellToDelete = nil

        Task {
            do {
                try await contentService.deleteHistory(id: item.id)
            } catch {
                presentAlert("Не удалось удалить запись")
            }
        }
    }

    func openHistoryCellDetails(_ item: HistoryCellModel) {
        guard coverTask == nil else { return }

        loadingTitle = "Открываем результат"
        coverTask = Task {
            defer { self.coverTask = nil }

            do {
                try await CoveredTransition.run(hide: { self.restoreCover() }) {
                    let details = try await self.contentService.fetchHistoryDetails(id: item.id)
                    
                    guard let route = self.route(for: details) else {
                        throw HistoryOpenError.missingResult
                    }
                    
                    return route
                } commit: { route in
                    self.historyRoutes.append(route)
                }
            } catch {
                self.presentAlert("Не удалось открыть результат")
            }
        }
    }

    private func restoreCover() {
        loadingTitle = historyCells.isEmpty && loadState == .loading ? Self.historyLoadTitle : nil
    }

    private func route(for details: HistoryCellModel) -> HistoryRoutes? {
        switch details.kind {
            case .personality:
                guard let result = details.personalityResult else { return nil }
                return .personalityResult(result)
            case .compatibility:
                guard let result = details.compatibilityResult else { return nil }
                return .compatibilityResult(result)
        }
    }
}

private enum HistoryOpenError: Error {
    case missingResult
}
