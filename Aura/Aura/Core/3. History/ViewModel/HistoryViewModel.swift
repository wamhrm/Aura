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
    case compatibilityResult(CompabilityResultModel)
}

@MainActor
final class HistoryViewModel: ObservableObject, AlertPresentable {
    @Published var historyRoutes: [HistoryRoutes] = []

    @Published private(set) var historyCells: [HistoryCellModel] = []
    @Published private(set) var loadState = LoadState.loading

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let storage: any LocalStorageProtocol

    private var currentUserId: UUID?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.authService = authService
        self.contentService = contentService
        self.storage = storage

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

        contentService.historyDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, let userId = currentUserId else { return }
                Task { await loadHistory(for: userId) }
            }
            .store(in: &cancellables)

        contentService.refreshRequested
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, let userId = currentUserId else { return }
                Task { await loadHistory(for: userId) }
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
        historyCells = storage.load(StorageKeys.history, for: user.id) ?? []
        loadState = historyCells.isEmpty ? .loading : .loaded

        Task { await loadHistory(for: user.id) }
    }

    func fetchHistory() async {
        guard let userId = currentUserId else { return }
        await loadHistory(for: userId, showErrorOnFailure: true)
    }

    func retry() {
        guard let userId = currentUserId else { return }

        loadState = .loading

        Task { await loadHistory(for: userId) }
    }

    private func loadHistory(for userId: UUID, showErrorOnFailure: Bool = false) async {
        do {
            let history = try await contentService.fetchHistory()
            guard currentUserId == userId else { return }

            historyCells = history
            loadState = .loaded
            storage.save(history, for: StorageKeys.history, userId: userId)
        } catch {
            guard currentUserId == userId, !error.isCancellation else { return }

            if historyCells.isEmpty {
                loadState = .failed(error.userMessage)
            } else if showErrorOnFailure {
                presentAlert(error.userMessage)
            }
        }
    }

    func deleteHistoryCell(_ item: HistoryCellModel) {
        Task {
            do {
                try await contentService.deleteHistory(id: item.id)
                historyCells.removeAll { $0.id == item.id }

                if let userId = currentUserId {
                    storage.save(historyCells, for: StorageKeys.history, userId: userId)
                }
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
