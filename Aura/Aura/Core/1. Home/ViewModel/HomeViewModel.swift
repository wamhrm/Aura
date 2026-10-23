//
//  HomeViewModel.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//


import Combine
import Foundation
import SwiftUI

enum HomeRoutes: Hashable {
    case addProfileInfo
    case horoscopeDetails
    case allTests
    case testDetails(PersonalityTestTypes)
    case testResults
}

@MainActor
final class HomeViewModel: ObservableObject, LoadingStatePresentable {
    @Published var homeRoutes: [HomeRoutes] = []

    @Published var profileInfo = ProfileInfoModel()
    @Published private(set) var userName = ""
    @Published private(set) var horoscope: HoroscopeModel?
    @Published private(set) var dailyInsight: DailyContentModel?
    @Published private(set) var personalityResult: PersonalityResultModel?
    @Published private(set) var selectedTests: [PersonalityTestTypes] = [.astrology, .behavioralPatterns]

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isSignedIn = false
    @Published private(set) var hasProfileInfo = false
    @Published private(set) var hasAIConsent = false
    @Published private(set) var isLoading = false
    @Published var isServerWakingUp = false
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

    var canTakeTests: Bool {
        hasProfileInfo && hasAIConsent
    }

    var dailyInsightHandler: String {
        dailyInsight?.text ?? "Сегодня у вас растет внутренее напряжение из-за невысказанных ожиданий."
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
        switch authState {
            case .signedIn(let user):
                isLoadingScreen = true
                profileInfo = user.profileInfo
                hasProfileInfo = user.hasCompletedProfileInfo
                hasAIConsent = user.allowsAIAnalysis
                userName = user.name
                isSignedIn = true

                if user.hasCompletedProfileInfo {
                    horoscope = storage.load(StorageKeys.horoscope, for: user.id)
                    dailyInsight = storage.load(StorageKeys.dailyInsight, for: user.id)

                    if !isLoading {
                        Task { await refreshHomeContent(for: user.id) }
                    }
                } else {
                    horoscope = nil
                    dailyInsight = nil
                    storage.delete(StorageKeys.horoscope, for: user.id)
                    storage.delete(StorageKeys.dailyInsight, for: user.id)
                }

                isLoadingScreen = false
            case .signedOut:
                isLoadingScreen = false
                profileInfo = ProfileInfoModel()
                hasProfileInfo = false
                hasAIConsent = false
                userName = ""
                horoscope = nil
                dailyInsight = nil
                personalityResult = nil
                homeRoutes = []
                isSignedIn = false
        }
    }

    func saveProfileInfo(onSuccess: @escaping () -> Void) {
        guard !isLoading else { return }

        isLoading = true

        Task {
            await withServerWakeUpIndicator(after: .seconds(20)) {
                do {
                    try validateProfileInfoForms()

                    let response = try await authService.updateProfileInfo(profileInfo)
                    profileInfo = response.user.profileInfo
                    hasProfileInfo = response.user.hasCompletedProfileInfo
                    hasAIConsent = response.user.allowsAIAnalysis
                    if let horoscope = response.horoscope {
                        self.horoscope = horoscope
                        storage.save(horoscope, for: StorageKeys.horoscope, userId: response.user.id)
                    } else {
                        await loadHoroscope(for: response.user.id, showErrorOnFailure: false)
                    }
                    if hasAIConsent {
                        await loadDailyInsight(for: response.user.id)
                    }
                    onSuccess()
                } catch {
                    presentAlert(error.localizedDescription)
                }
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

        Task {
            isLoading = true

            await withServerWakeUpIndicator(after: .seconds(20)) {
                do {
                    personalityResult = try await contentService.makePersonalityTest(selectedTests: selectedTests)
                    homeRoutes.append(.testResults)
                } catch {
                    presentAlert((error as? LocalizedError)?.errorDescription ?? "Не удалось получить результат")
                }
            }

            isLoading = false
        }
    }

    private func loadHoroscope(for userId: UUID, showErrorOnFailure: Bool) async {
        do {
            let fetched = try await contentService.fetchCurrentHoroscope()
            horoscope = fetched
            storage.save(fetched, for: StorageKeys.horoscope, userId: userId)
        } catch {
            if showErrorOnFailure {
                presentAlert(error.localizedDescription)
            }
        }
    }

    private func loadDailyInsight(for userId: UUID, showErrorOnFailure: Bool = true) async {
        do {
            let insight = try await contentService.fetchDailyInsight()
            dailyInsight = insight
            storage.save(insight, for: StorageKeys.dailyInsight, userId: userId)
        } catch {
            if showErrorOnFailure {
                presentAlert(error.localizedDescription)
            }
        }
    }

    private func refreshHomeContent(for userId: UUID) async {
        await loadHoroscope(for: userId, showErrorOnFailure: false)

        guard hasAIConsent else { return }
        await loadDailyInsight(for: userId, showErrorOnFailure: false)
    }

    private func validateProfileInfoForms() throws {
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

}

fileprivate enum ProfileInfoError: LocalizedError {
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
