//
//  CompatibilityViewModel.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import Combine
import Foundation

enum CompatibilityRoutes: Hashable {
    case testDetails(CompatibilityTestTypes)
    case compatibilityResults
}

@MainActor
final class CompatibilityViewModel: ObservableObject {
    @Published var compatibilityRoutes: [CompatibilityRoutes] = []
    @Published var partnerInfo = PartnerInfoModel()
    
    @Published var selectedTests: [CompatibilityTestTypes] = [.astrology, .behavioralPatterns, .attachmentCompatibility]
    @Published var compatibilityResult: CompabilityResultModel?
    
    @Published var showAlert = false
    @Published private(set) var alertMessage = ""
    @Published private(set) var isLoading = false

    private let psychologyService: any PsychologyServiceProtocol

    init(psychologyService: any PsychologyServiceProtocol) {
        self.psychologyService = psychologyService
    }

    func toggleTestSelection(_ test: CompatibilityTestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > 3 else {
                showAlert(message: "Нельзя выбрать меньше 3 тестов")
                return
            }

            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }

    func makeCompatibilityTest() {
        guard !isLoading else { return }

        Task {
            isLoading = true

            do {
                let request = partnerInfo.compatibilityTestRequest(selectedTests: selectedTests)
                compatibilityResult = try await psychologyService.makeCompatibilityTest(request: request)
                compatibilityRoutes.append(.compatibilityResults)
            } catch {
                showAlert(message: "Не удалось получить результат")
            }

            isLoading = false
        }
    }

    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
