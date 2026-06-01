//
//  HistoryViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Combine
import Foundation
import SwiftUI

enum HistoryRoutes: Hashable {
    case personalityResult(PersonalityResultModel)
    case compatibilityResult(CompabilityResultModel)
}

@MainActor
final class HistoryViewModel: ObservableObject, LoadingStatePresentable {
    @Published var historyRoutes: [HistoryRoutes] = []
    @Published private(set) var historyCells: [HistoryCellModel] = []

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isSignedIn = false
    @Published private(set) var isLoading = false
    @Published var isServerWakingUp = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var currentUserId: UUID?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
            }
            .store(in: &cancellables)

        contentService.historyDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, let userId = currentUserId else { return }
                Task { await self.fetchHistory(for: userId, ignoreCache: true) }
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ state: AuthState) {
        switch state {
            case .signedIn(let user):
                currentUserId = user.id
                historyCells = UserDefaultsHelper.getLocalHistory(for: user.id) ?? []
                isSignedIn = true
                Task { await fetchHistory(for: user.id, ignoreCache: true) }
            case .signedOut:
                currentUserId = nil
                isSignedIn = false
                isServerWakingUp = false
                historyCells = []
                historyRoutes = []
        }
    }

    func fetchHistory() {
        guard let userId = currentUserId else { return }
        Task { await fetchHistory(for: userId, ignoreCache: true) }
    }

    private func fetchHistory(for userId: UUID, ignoreCache: Bool = false) async {
        if !ignoreCache, let cached = UserDefaultsHelper.getLocalHistory(for: userId) {
            historyCells = cached
            return
        }

        do {
            let history = try await contentService.fetchHistory()
            historyCells = history
            UserDefaultsHelper.saveHistoryLocally(history, for: userId)
        } catch {
            presentAlert("Не удалось загрузить историю")
        }
    }

    func deleteHistoryCell(_ item: HistoryCellModel) {
        Task {
            do {
                try await contentService.deleteHistory(id: item.id)
                historyCells.removeAll { $0.id == item.id }
                if let userId = currentUserId {
                    UserDefaultsHelper.saveHistoryLocally(historyCells, for: userId)
                }
            } catch {
                presentAlert("Не удалось удалить запись")
            }
        }
    }

    func openHistoryCellDetails(_ item: HistoryCellModel) {
        guard !isServerWakingUp && !isLoading else { return }
        
        isLoading = true

        Task {
            await withServerWakeUpIndicator(after: .seconds(8)) {
                do {
                    let historyDetails = try await contentService.fetchHistoryDetails(id: item.id)

                    switch historyDetails.kind {
                        case .personality:
                            guard let result = historyDetails.personalityResult else {
                                presentAlert("Не удалось открыть результат")
                                return
                            }
                            historyRoutes.append(.personalityResult(result))
                        case .compatibility:
                            guard let result = historyDetails.compatibilityResult else {
                                presentAlert("Не удалось открыть результат")
                                return
                            }
                            historyRoutes.append(.compatibilityResult(result))
                    }
                } catch {
                    presentAlert("Не удалось открыть результат")
                }
            }
            
            isLoading = false
        }
    }
}
