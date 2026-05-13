//
//  HomeViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import SwiftUI
import Combine

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
    @Published var profileInfo = ProfileInfoForm()
    @Published private(set) var hasProfileInfo = false
    @Published private(set) var isSavingProfileInfo = false
    @Published var profileInfoErrorMessage: String?
    @Published var showProfileInfoError = false

    @Published var selectedTests: [TestTypes] = []
    @Published var showMinTestsAlert = false
    @Published private(set) var personalityAnalysisResult: PersonalityAnalysisResult?
    @Published private(set) var isGeneratingPersonalityAnalysis = false
    @Published var personalityAnalysisErrorMessage: String?
    @Published var showPersonalityAnalysisError = false

    private let minSelectedTests = 2
    private let authService: any AuthServiceProtocol
    private let personalityAnalysisService: any PersonalityAnalysisServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         personalityAnalysisService: (any PersonalityAnalysisServiceProtocol)? = nil) {
        self.authService = authService
        self.personalityAnalysisService = personalityAnalysisService ?? PersonalityAnalysisService()

        minimumSelectedTests()
        updateProfileInfo(from: authService.authState)
        setupSubscriptions()
    }

    deinit {
        cancellables.removeAll()
    }

    func toggleTestSelection(_ test: TestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > minSelectedTests else {
                showMinTestsAlert = true
                return
            }

            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }

    func generatePersonalityAnalysis() {
        guard selectedTests.count >= minSelectedTests else {
            showMinTestsAlert = true
            return
        }

        guard !isGeneratingPersonalityAnalysis else { return }

        Task {
            isGeneratingPersonalityAnalysis = true

            do {
                personalityAnalysisResult = try await personalityAnalysisService.generate(selectedTests: selectedTests)
                homeRoutes.append(.testResults)
            } catch {
                personalityAnalysisErrorMessage = error.localizedDescription
                showPersonalityAnalysisError = true
            }

            isGeneratingPersonalityAnalysis = false
        }
    }

    func saveProfileInfo() {
        guard !isSavingProfileInfo else { return }

        Task {
            isSavingProfileInfo = true

            do {
                let request = try profileInfo.request()
                let user = try await authService.updateProfileInfo(request)
                profileInfo = ProfileInfoForm(user: user)
                hasProfileInfo = true
                homeRoutes.removeAll()
            } catch {
                profileInfoErrorMessage = error.localizedDescription
                showProfileInfoError = true
            }

            isSavingProfileInfo = false
        }
    }

    private func setupSubscriptions() {
        authService.authStatePublisher
            .sink { [weak self] authState in
                Task { @MainActor in
                    self?.updateProfileInfo(from: authState)
                }
            }
            .store(in: &cancellables)
    }

    private func updateProfileInfo(from authState: AuthState) {
        switch authState {
            case .signedIn(let user):
                profileInfo = ProfileInfoForm(user: user)
                hasProfileInfo = user.hasCompletedProfileInfo
            case .signedOut:
                profileInfo = ProfileInfoForm()
                hasProfileInfo = false
        }
    }

    private func minimumSelectedTests() {
        if selectedTests.count < minSelectedTests {
            selectedTests = Array(TestTypes.allCases.prefix(minSelectedTests))
        }
    }
}

struct ProfileInfoForm {
    var dateOfBirth = ""
    var birthTime = ""
    var gender: AddProfileInfoCellType.Gender?
    var socialType: AddProfileInfoCellType.SocialType?
    var conflictStyle: AddProfileInfoCellType.ConflictStyle?
    var emotionalCore: AddProfileInfoCellType.EmotionalCore?
    var decisionStyle: AddProfileInfoCellType.DecisionStyle?
    var coreFocus: AddProfileInfoCellType.CoreRelationshipFocus?

    init() { }

    init(user: UserModel) {
        dateOfBirth = user.dateOfBirth ?? ""
        birthTime = user.birthTime ?? ""
        gender = user.gender.flatMap(AddProfileInfoCellType.Gender.init(rawValue:))
        socialType = user.socialType.flatMap(AddProfileInfoCellType.SocialType.init(rawValue:))
        conflictStyle = user.conflictStyle.flatMap(AddProfileInfoCellType.ConflictStyle.init(rawValue:))
        emotionalCore = user.emotionalCore.flatMap(AddProfileInfoCellType.EmotionalCore.init(rawValue:))
        decisionStyle = user.decisionStyle.flatMap(AddProfileInfoCellType.DecisionStyle.init(rawValue:))
        coreFocus = user.coreFocus.flatMap(AddProfileInfoCellType.CoreRelationshipFocus.init(rawValue:))
    }

    func request() throws -> UpdateProfileInfoRequest {
        guard dateOfBirth.count == 10 else { throw HomeError.invalidDateOfBirth }

        guard let gender,
              let socialType,
              let conflictStyle,
              let emotionalCore,
              let decisionStyle,
              let coreFocus else { throw HomeError.incompleteProfileInfo }

        return UpdateProfileInfoRequest(dateOfBirth: dateOfBirth,
                                        birthTime: birthTime.isEmpty ? nil : birthTime,
                                        gender: gender.rawValue,
                                        socialType: socialType.rawValue,
                                        conflictStyle: conflictStyle.rawValue,
                                        emotionalCore: emotionalCore.rawValue,
                                        decisionStyle: decisionStyle.rawValue,
                                        coreFocus: coreFocus.rawValue)
    }
}

struct UpdateProfileInfoRequest: Encodable {
    let dateOfBirth: String
    let birthTime: String?
    let gender: String
    let socialType: String
    let conflictStyle: String
    let emotionalCore: String
    let decisionStyle: String
    let coreFocus: String
}

private enum HomeError: LocalizedError {
    case invalidDateOfBirth
    case incompleteProfileInfo

    var errorDescription: String? {
        switch self {
            case .invalidDateOfBirth:
                return "Укажите дату рождения в формате ДД.ММ.ГГГГ"
            case .incompleteProfileInfo:
                return "Заполните все обязательные поля профиля"
        }
    }
}
