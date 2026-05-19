//
//  HistoryViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import Combine

enum HistoryRoutes: Hashable {
    case testResult(PersonalityResultModel)
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
    }

    private func fetchHistory() {
        guard isSignedIn else {
            historyCells = []
            return
        }

        Task {
            do {
                historyCells = try await psychologyService.fetchPersonalityTests()
            } catch {
                showAlert(message: "Не удалось загрузить историю")
            }
        }
    }

    func openHistoryCellDetails(_ item: HistoryCellModel) {
        Task {
            do {
                let detail = try await psychologyService.fetchPersonalityTestDetails(id: item.id)
                historyRoutes.append(.testResult(detail.result))
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
