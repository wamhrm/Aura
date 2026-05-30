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
final class CompatibilityViewModel: ObservableObject {
    @Published var compatibilityRoutes: [CompatibilityRoutes] = []

    @Published var selectedTests: [CompatibilityTestTypes] = [.astrology, .behavioralPatterns, .attachmentCompatibility]
    @Published var partnerInfo = PartnerInfoModel()
    @Published private(set) var compatibilityResult: CompabilityResultModel?

    @Published var showAlert = false
    @Published private(set) var alertMessage = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isServerWakingUp = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

        setupSubscriptions()
    }

    deinit {
        cancellables.removeAll()
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
                showAlert("Нельзя выбрать меньше 3 тестов")
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
            let loadedTask = Task {
                try await Task.sleep(for: .seconds(25))

                if !Task.isCancelled {
                    withAnimation { isServerWakingUp = true }
                }
            }

            defer { loadedTask.cancel() }

            do {
                try validatePartnerInfoForms()
                let request = partnerInfo.compatibilityTestRequest(selectedTests: selectedTests)
                compatibilityResult = try await contentService.makeCompatibilityTest(request: request)
                compatibilityRoutes.append(.compatibilityResults)
            } catch {
                showAlert(error.localizedDescription)
            }

            withAnimation { isServerWakingUp = false }
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
        showAlert("Укажите корректную дату рождения")
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        showAlert = true
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
