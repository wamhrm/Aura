//
//  HistoryViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Combine
import Foundation

enum HistoryRoutes: Hashable {
    case personalityResult(PersonalityResultModel)
    case compatibilityResult(CompabilityResultModel)
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var historyRoutes: [HistoryRoutes] = []
    @Published private(set) var historyCells: [HistoryCellModel] = []
    @Published private(set) var isSignedIn = false
    
    @Published var showError = false
    @Published private(set) var errorMessage = ""

    private let authService: any AuthServiceProtocol
    private let psychologyService: any PsychologyServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         psychologyService: any PsychologyServiceProtocol) {
        self.authService = authService
        self.psychologyService = psychologyService

        setupSubscriptions()
    }

    deinit {
        cancellables.removeAll()
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] authState in
                guard let self else { return }
                switch authState {
                    case .signedIn:
                        isSignedIn = true
                        fetchHistory()
                    case .signedOut:
                        isSignedIn = false
                        historyCells = []
                        historyRoutes = []
                }
            }
            .store(in: &cancellables)

        psychologyService.historyDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, isSignedIn else { return }
                fetchHistory()
            }
            .store(in: &cancellables)
    }

    private func fetchHistory() {
        Task {
            do {
                historyCells = try await psychologyService.fetchHistory()
            } catch {
                showAlert(message: "Не удалось загрузить историю")
            }
        }
    }

    func deleteHistoryCell(_ item: HistoryCellModel) {
        Task {
            do {
                try await psychologyService.deleteHistory(id: item.id)
                historyCells.removeAll { $0.id == item.id }
            } catch {
                showAlert(message: "Не удалось удалить запись")
            }
        }
    }

    func openHistoryCellDetails(_ item: HistoryCellModel) {
        Task {
            do {
                let detail = try await psychologyService.fetchHistoryDetails(id: item.id)

                switch detail.kind {
                    case .personality:
                        guard let result = detail.personalityResult else {
                            showAlert(message: "Не удалось открыть результат")
                            return
                        }
                        historyRoutes.append(.personalityResult(result))
                    case .compatibility:
                        guard let result = detail.compatibilityResult else {
                            showAlert(message: "Не удалось открыть результат")
                            return
                        }
                        historyRoutes.append(.compatibilityResult(result))
                }
            } catch {
                showAlert(message: "Не удалось открыть результат")
            }
        }
    }

    private func showAlert(message: String) {
        errorMessage = message
        showError = true
    }
}
