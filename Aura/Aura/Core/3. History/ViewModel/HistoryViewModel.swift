//
//  HistoryViewModel.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Combine
import Foundation
import SwiftUI

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
        if historyCells.isEmpty { loadState = .loading }

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
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                let historyDetails = try await contentService.fetchHistoryDetails(id: item.id)

                switch historyDetails.kind {
                    case .personality:
                        if let result = historyDetails.personalityResult {
                            historyRoutes.append(.personalityResult(result))
                        } else {
                            presentAlert("Не удалось открыть результат")
                        }
                    case .compatibility:
                        if let result = historyDetails.compatibilityResult {
                            historyRoutes.append(.compatibilityResult(result))
                        } else {
                            presentAlert("Не удалось открыть результат")
                        }
                }
            } catch {
                presentAlert("Не удалось открыть результат")
            }

            isLoading = false
        }
    }
}
