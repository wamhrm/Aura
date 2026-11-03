//
//  CompatibilityViewModel.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Combine
import Foundation
import SwiftUI

enum CompatibilityRoutes: Hashable {
    case testDetails(CompatibilityTestTypes)
    case compatibilityResults
}

enum CompatibilityButtons {
    enum genderOptions: String, CaseIterable {
        case male = "Мужской"
        case female = "Женский"

        var key: String {
            switch self {
                case .male: ProfileInfoOption.man.rawValue
                case .female: ProfileInfoOption.woman.rawValue
            }
        }
    }

    enum birthOptions: String, CaseIterable {
        case exactDate = "Точная"
        case approximateDate = "Примерная"
    }
}

@MainActor
final class CompatibilityViewModel: ObservableObject, AlertPresentable {
    @Published var compatibilityRoutes: [CompatibilityRoutes] = []
    @Published var selectedTests: [CompatibilityTestTypes] = [.astrology, .behavioralPatterns, .attachmentCompatibility]
    @Published var partnerInfo = PartnerInfoModel()
    @Published private(set) var compatibilityResult: CompabilityResultModel?

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false
    @Published private(set) var needsAIConsent = false
    @Published var emailConfirmation: EmailConfirmationViewModel?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    
    private var currentUser: UserModel?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

        setupSubscriptions()
    }

    var testButtonTitle: String {
        isLoading ? "Готовим результат..." : "Узнать совместимость"
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, case .signedIn(let user) = $0 else { return }
                currentUser = user
                needsAIConsent = !user.allowsAIAnalysis
                if user.hasConfirmedEmail { emailConfirmation = nil }
            }
            .store(in: &cancellables)
    }

    func showTestDetails(_ test: CompatibilityTestTypes) {
        compatibilityRoutes.append(.testDetails(test))
    }

    func selectAllTests() {
        selectedTests = CompatibilityTestTypes.allCases
    }

    func isSelected(_ test: CompatibilityTestTypes) -> Bool {
        selectedTests.contains(test)
    }

    func selectGender(_ option: CompatibilityButtons.genderOptions) {
        partnerInfo.gender = option.key
    }

    func selectBirthOption(_ option: CompatibilityButtons.birthOptions) {
        partnerInfo.exactDateOfBirth = option == .exactDate
    }

    func toggleTestSelection(_ test: CompatibilityTestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > InputLimits.minCompatibilityTests else {
                presentAlert("Нельзя выбрать меньше \(InputLimits.minCompatibilityTests) тестов")
                return
            }

            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }

    func makeCompatibilityTest() {
        guard !isLoading else { return }

        if let currentUser, !currentUser.hasConfirmedEmail {
            emailConfirmation = EmailConfirmationViewModel(authService: authService, email: currentUser.email ?? "")
            return
        }

        isLoading = true

        Task {
            do {
                try validatePartnerInfoForms()
                let request = partnerInfo.compatibilityTestRequest(selectedTests: selectedTests)
                compatibilityResult = try await contentService.makeCompatibilityTest(request: request)
                compatibilityRoutes.append(.compatibilityResults)
            } catch {
                presentAlert(error.userMessage)
            }
            
            isLoading = false
        }
    }

    private func validatePartnerInfoForms() throws {
        let name = partnerInfo.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard name.count >= InputLimits.minNameLength else {
            throw PartnerInfoError.invalidName
        }

        if partnerInfo.exactDateOfBirth {
            guard partnerInfo.dateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines).count == 10 else {
                throw PartnerInfoError.invalidDateOfBirth
            }
        } else {
            let age = partnerInfo.age.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Int(age), (InputLimits.minPartnerAge...InputLimits.maxPartnerAge).contains(value) else {
                throw PartnerInfoError.invalidAge
            }
        }
    }
    
    func showInvalidDateOfBirthday() {
        presentAlert("Укажите корректную дату рождения")
    }

    func clearFields() {
        partnerInfo.name = ""
        partnerInfo.dateOfBirth = ""
        partnerInfo.birthTime = ""
        partnerInfo.age = ""
    }
}

fileprivate enum PartnerInfoError: LocalizedError {
    case invalidName, invalidDateOfBirth, invalidAge

    var errorDescription: String? {
        switch self {
            case .invalidName: "Имя партнёра должно содержать минимум \(InputLimits.minNameLength) символа"
            case .invalidDateOfBirth: "Укажите дату рождения в формате ДД.ММ.ГГГГ"
            case .invalidAge: "Возраст партнёра должен быть от \(InputLimits.minPartnerAge) до \(InputLimits.maxPartnerAge) лет"
        }
    }
}
