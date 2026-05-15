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
    case testDetails(PersonalityTestTypes)
    case testResults
    case horoscopeDetails
    case addProfileInfo
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var homeRoutes: [HomeRoutes] = []
    
    @Published var profileInfo = ProfileInfoModel()
    @Published private(set) var hasProfileInfo = false
    
    @Published var selectedTests: [PersonalityTestTypes] = [.astrology, .behavioralPatterns]
    @Published var personalityResult: PersonalityResultModel?
    
    @Published var showError = false
    @Published var errorMessage = ""
    @Published private(set) var isLoading = false

    private let authService: any AuthServiceProtocol
    private let psychologyService: any PsychologyServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         psychologyService: any PsychologyServiceProtocol) {
        self.authService = authService
        self.psychologyService = psychologyService
        
        setupSubscriptions()
        applyAuthState(authService.authState.value)
    }

    deinit {
        cancellables.removeAll()
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] authState in
                self?.applyAuthState(authState)
            }
            .store(in: &cancellables)
    }

    private func applyAuthState(_ authState: AuthState) {
        switch authState {
            case .signedIn(let user):
                profileInfo = user.profileInfo
                hasProfileInfo = user.hasCompletedProfileInfo
            case .signedOut:
                profileInfo = ProfileInfoModel()
                hasProfileInfo = false
        }
    }

    func toggleTestSelection(_ test: PersonalityTestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > 2 else {
                showAlert(message: "Нельзя выбрать меньше 2 тестов")
                return
            }
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
                personalityResult = try await psychologyService.makePersonalityTest(selectedTests: selectedTests)
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
