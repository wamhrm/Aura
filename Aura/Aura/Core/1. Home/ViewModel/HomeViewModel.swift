//
//  HomeViewModel.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//


import Combine
import Foundation

enum HomeRoutes: Hashable {
    case tests
    case testDetails(TestTypes)
    case testResults
    case horoscopeDetails
    case addProfileInfo
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var homeRoutes: [HomeRoutes] = []
    @Published var profileInfo = ProfileInfoModel()
    @Published private(set) var hasProfileInfo = false
    @Published var selectedTests: [TestTypes] = [.astrology, .attachmentStyle]
    @Published var showError = false
    @Published var errorMessage = ""
    @Published private(set) var isLoading = false
    @Published var personalityResult: PersonalityResult?

    private let authService: any AuthServiceProtocol
    private let personalityService: any PersonalityServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         personalityService: any PersonalityServiceProtocol) {
        self.authService = authService
        self.personalityService = personalityService
        self.personalityResult = .mock
    }

    deinit {
        cancellables.removeAll()
    }

    func toggleTestSelection(_ test: TestTypes) {
        guard selectedTests.count > 2 else {
            showAlert(message: "Нельзя выбрать меньше 2 тестов")
            return
        }

        if let index = selectedTests.firstIndex(of: test) {
            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }

    func generatePersonality() {
        guard !isLoading else { return }

        Task {
            isLoading = true

            do {
                personalityResult = try await personalityService.generate(selectedTests: selectedTests)
                homeRoutes.append(.testResults)
            } catch {
                showAlert(message: "Не удалось получить результат")
            }

            isLoading = false
        }
    }

    func saveProfileInfo() {
        guard !isLoading else { return }
        
        Task {
            isLoading = true

            do {
                try validateProfileForms()
                let user = try await authService.updateProfileInfo(profileInfo)
                profileInfo = user.profileInfo
                hasProfileInfo = true
                homeRoutes.removeAll()
            } catch {
                showAlert(message: error.localizedDescription)
            }

            isLoading = false
        }
    }
    
    private func validateProfileForms() throws {
        guard profileInfo.dateOfBirth.count == 10 else {
            throw ProfileInfoError.invalidDateOfBirth
        }

        guard profileInfo.gender != nil,
              profileInfo.socialType != nil,
              profileInfo.conflictStyle != nil,
              profileInfo.emotionalCore != nil,
              profileInfo.decisionStyle != nil,
              profileInfo.coreFocus != nil else {
            throw ProfileInfoError.incompleteProfileInfo
        }
    }

    private func showAlert(message: String) {
        errorMessage = message
        showError = true
    }
}
