//
//  HomeViewModel.swift
//  Aura
//
//  Created by wamhrm on 05.05.2026.
//


import Combine
import Foundation
import SwiftUI

enum HomeRoutes: Hashable {
    case horoscopeDetails, allTests, testResults
    case testDetails(PersonalityTestTypes)
}

@MainActor
final class HomeViewModel: ObservableObject, AlertPresentable {
    @Published var homeRoutes: [HomeRoutes] = []

    @Published var profileInfo = ProfileInfoModel()
    @Published private(set) var userName = ""
    @Published private(set) var horoscope: HoroscopeModel?
    @Published private(set) var dailyInsight: DailyContentModel?
    @Published private(set) var personalityResult: PersonalityResultModel?
    @Published private(set) var selectedTests: [PersonalityTestTypes] = [.astrology, .behavioralPatterns]

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var allowsAIAnalysis = false
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingScreen = true

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let storage: any LocalStorageProtocol

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.authService = authService
        self.contentService = contentService
        self.storage = storage

        setupSubscriptions()
    }

    var dailyInsightHandler: String {
        dailyInsight?.text ?? "Сегодня у вас растет внутренее напряжение из-за невысказанных ожиданий."
    }

    var greetingText: String {
        "Здравствуйте, \(userName.capitalized)"
    }

    var testButtonTitle: String {
        isLoading ? "Готовим результат..." : "Проверить себя"
    }

    var saveButtonTitle: String {
        isLoading ? "Сохраняем..." : "Готово"
    }

    func isSelected(_ test: PersonalityTestTypes) -> Bool {
        selectedTests.contains(test)
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                handleProfileInfo($0)
            }
            .store(in: &cancellables)
    }

    private func handleProfileInfo(_ authState: AuthState) {
        guard case .signedIn(let user) = authState else { return }

        profileInfo = user.profileInfo
        allowsAIAnalysis = user.allowsAIAnalysis
        userName = user.name
        horoscope = storage.load(StorageKeys.horoscope, for: user.id)
        dailyInsight = storage.load(StorageKeys.dailyInsight, for: user.id)
        isLoadingScreen = false

        if !isLoading {
            Task { await refreshHomeContent(for: user.id) }
        }
    }

    func showHoroscopeDetails() {
        homeRoutes.append(.horoscopeDetails)
    }

    func showAllTests() {
        homeRoutes.append(.allTests)
    }

    func showTestDetails(_ test: PersonalityTestTypes) {
        homeRoutes.append(.testDetails(test))
    }

    func saveProfileInfo(onSuccess: @escaping () -> Void) {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try validateProfileInfoForms()

                let response = try await authService.updateProfileInfo(profileInfo)
                profileInfo = response.user.profileInfo
                allowsAIAnalysis = response.user.allowsAIAnalysis
                if let horoscope = response.horoscope {
                    self.horoscope = horoscope
                } else {
                    await loadHoroscope(for: response.user.id)
                }
                if allowsAIAnalysis {
                    await loadDailyInsight(for: response.user.id)
                }
                onSuccess()
            } catch {
                presentAlert(error.userMessage)
            }
            
            isLoading = false
        }
    }

    func toggleTestSelection(_ test: PersonalityTestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > 2 else {
                presentAlert("Нельзя выбрать меньше 2 тестов")
                return
            }
            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }

    func makePersonalityTest() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                personalityResult = try await contentService.makePersonalityTest(selectedTests: selectedTests)
                homeRoutes.append(.testResults)
            } catch {
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }

    private func loadHoroscope(for userId: UUID) async {
        if let fetched = try? await contentService.fetchCurrentHoroscope(for: userId) {
            horoscope = fetched
        }
    }

    private func loadDailyInsight(for userId: UUID, showErrorOnFailure: Bool = true) async {
        do {
            dailyInsight = try await contentService.fetchDailyInsight(for: userId)
        } catch {
            if showErrorOnFailure {
                presentAlert(error.userMessage)
            }
        }
    }

    private func refreshHomeContent(for userId: UUID) async {
        await loadHoroscope(for: userId)

        guard allowsAIAnalysis else { return }
        await loadDailyInsight(for: userId, showErrorOnFailure: false)
    }

    private func validateProfileInfoForms() throws {
        guard profileInfo.dateOfBirth.count == 10 else {
            throw ProfileInfoError.invalidDateOfBirth
        }

        guard profileInfo.hasAllAnswers else {
            throw ProfileInfoError.incompleteProfileInfo
        }
    }

}

fileprivate enum ProfileInfoError: LocalizedError {
    case invalidDateOfBirth, incompleteProfileInfo

    var errorDescription: String? {
        switch self {
            case .invalidDateOfBirth: "Укажите дату рождения в формате ДД.ММ.ГГГГ"
            case .incompleteProfileInfo: "Заполните все обязательные поля профиля"
        }
    }
}
