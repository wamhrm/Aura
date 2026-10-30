//
//  HistoryViewModel.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
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
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, case .signedIn(let user) = $0 else { return }
                handleSignIn(user)
            }
            .store(in: &cancellables)

        contentService.historyDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, let userId = currentUserId else { return }
                Task { await fetchHistory(for: userId) }
            }
            .store(in: &cancellables)
    }

    private func handleSignIn(_ user: UserModel) {
        currentUserId = user.id
        historyCells = storage.load(StorageKeys.history, for: user.id) ?? []
        Task { await fetchHistory(for: user.id) }
    }

    func fetchHistory() async {
        guard let userId = currentUserId else { return }
        await fetchHistory(for: userId)
    }

    private func fetchHistory(for userId: UUID) async {
        do {
            let history = try await contentService.fetchHistory()
            historyCells = history
            storage.save(history, for: StorageKeys.history, userId: userId)
        } catch {
            presentAlert(error.userMessage)
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
