//
//  CompatibilityViewModel.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import Combine
import Foundation
import SwiftUI

enum CompatibilityRoutes: Hashable {
    case testDetails(CompatibilityTestTypes)
    case compatibilityResults
}

@MainActor
final class CompatibilityViewModel: ObservableObject, LoadingStatePresentable {
    @Published var compatibilityRoutes: [CompatibilityRoutes] = []

    @Published var selectedTests: [CompatibilityTestTypes] = [.astrology, .behavioralPatterns, .attachmentCompatibility]
    @Published var partnerInfo = PartnerInfoModel()
    @Published private(set) var compatibilityResult: CompabilityResultModel?

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false
    @Published var isServerWakingUp = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    
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

                if case .signedOut = $0 {
                    compatibilityRoutes = []
                    compatibilityResult = nil
                }
            }
            .store(in: &cancellables)
    }

    func toggleTestSelection(_ test: CompatibilityTestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > 3 else {
                presentAlert("Нельзя выбрать меньше 3 тестов")
                return
            }

            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }

    func makeCompatibilityTest() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            await withServerWakeUpIndicator(after: .seconds(20)) {
                do {
                    try validatePartnerInfoForms()
                    let request = partnerInfo.compatibilityTestRequest(selectedTests: selectedTests)
                    compatibilityResult = try await contentService.makeCompatibilityTest(request: request)
                    compatibilityRoutes.append(.compatibilityResults)
                } catch {
                    presentAlert(error.localizedDescription)
                }
            }
            
            isLoading = false
        }
    }

    private func validatePartnerInfoForms() throws {
        let name = partnerInfo.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard name.count >= 2 else {
            throw PartnerInfoError.invalidName
        }

        if partnerInfo.exactDateOfBirth {
            guard partnerInfo.dateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines).count == 10 else {
                throw PartnerInfoError.invalidDateOfBirth
            }
        } else {
            let age = partnerInfo.age.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Int(age), value > 0 else {
                throw PartnerInfoError.invalidAge
            }
        }
    }
    
    func showInvalidDateOfBirthday() {
        presentAlert("Укажите корректную дату рождения")
    }
}

fileprivate enum PartnerInfoError: LocalizedError {
    case invalidName
    case invalidDateOfBirth
    case invalidAge

    var errorDescription: String? {
        switch self {
            case .invalidName:
                return "Имя партнёра должно содержать минимум 2 символа"
            case .invalidDateOfBirth:
                return "Укажите дату рождения в формате ДД.ММ.ГГГГ"
            case .invalidAge:
                return "Укажите возраст партнёра"
        }
    }
}
