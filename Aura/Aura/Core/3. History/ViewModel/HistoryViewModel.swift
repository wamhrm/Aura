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
    @Published private(set) var isLoading = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var currentUserId: UUID?
    private var cellToDelete: HistoryCellModel?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService
        self.historyCells = contentService.historyCells.value

        setupSubscriptions()
    }

    var showsLoadingScreen: Bool {
        isLoading || (historyCells.isEmpty && loadState == .loading)
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
            }
            .store(in: &cancellables)

        contentService.historyState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.loadState = $0 }
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
        let sessionID = authService.sessionID

        do {
            _ = try await contentService.fetchHistory()
        } catch {
            guard sessionID == authService.sessionID else { return }
            if !contentService.historyCells.value.isEmpty {
                presentAlert(error.userMessage)
            }
        }
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
                presentAlert(AppLanguage.text("Не удалось удалить запись"))
            }
        }
    }

    func openHistoryCellDetails(_ item: HistoryCellModel) {
        guard !isLoading else { return }

        isLoading = true
        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                let details = try await contentService.fetchHistoryDetails(id: item.id)
                guard let route = route(for: details) else {
                    throw HistoryOpenError.missingResult
                }

                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                historyRoutes.append(route)
                try await Task.sleep(for: .milliseconds(50))
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(AppLanguage.text("Не удалось открыть результат"))
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
        }
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
