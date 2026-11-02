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

    @Published private(set) var userName = ""
    @Published private(set) var horoscope: HoroscopeModel?
    @Published private(set) var horoscopeState = LoadState.loading
    @Published private(set) var dailyInsight: DailyContentModel?
    @Published private(set) var insightState = LoadState.loading
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

    private var currentUser: UserModel?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.authService = authService
        self.contentService = contentService
        self.storage = storage

        setupSubscriptions()
    }

    var greetingText: String {
        "Здравствуйте, \(userName.capitalized)"
    }

    var testButtonTitle: String {
        isLoading ? "Готовим результат..." : "Проверить себя"
    }

    func isSelected(_ test: PersonalityTestTypes) -> Bool {
        selectedTests.contains(test)
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
            }
            .store(in: &cancellables)

        contentService.refreshRequested
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await refresh() }
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ authState: AuthState) {
        switch authState {
            case .signedIn(let user):
                handleUser(user)
            case .signedOut:
                guard currentUser != nil else { return }
                currentUser = nil
                cancellables.removeAll()
        }
    }

    private func handleUser(_ user: UserModel) {
        let previousUser = currentUser

        currentUser = user
        allowsAIAnalysis = user.allowsAIAnalysis
        userName = user.name
        isLoadingScreen = false

        guard let previousUser, previousUser.id == user.id else {
            horoscope = storage.load(StorageKeys.horoscope, for: user.id)
            let cachedInsight = storage.load(StorageKeys.dailyInsight, for: user.id)
            dailyInsight = cachedInsight?.isFromToday == true ? cachedInsight : nil
            Task { await refresh() }
            return
        }

        if previousUser.dateOfBirth != user.dateOfBirth {
            Task { await loadHoroscope(for: user.id) }
        }

        if !previousUser.allowsAIAnalysis && user.allowsAIAnalysis {
            Task { await loadDailyInsight(for: user.id) }
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

    func toggleTestSelection(_ test: PersonalityTestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > InputLimits.minPersonalityTests else {
                presentAlert("Нельзя выбрать меньше \(InputLimits.minPersonalityTests) тестов")
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

    func refresh() async {
        guard let user = currentUser else { return }

        async let horoscopeLoad: Void = loadHoroscope(for: user.id)

        if user.allowsAIAnalysis {
            await loadDailyInsight(for: user.id)
        }

        await horoscopeLoad
    }

    func retryHoroscope() {
        guard let user = currentUser else { return }
        Task { await loadHoroscope(for: user.id) }
    }

    func retryDailyInsight() {
        guard let user = currentUser else { return }
        Task { await loadDailyInsight(for: user.id) }
    }

    private func loadHoroscope(for userId: UUID) async {
        if horoscope == nil {
            horoscopeState = .loading
        }

        do {
            let fetched = try await contentService.fetchCurrentHoroscope(for: userId)
            guard currentUser?.id == userId else { return }

            horoscope = fetched
            horoscopeState = .loaded
        } catch {
            guard currentUser?.id == userId, !error.isCancellation else { return }

            if horoscope == nil {
                horoscopeState = .failed(error.userMessage)
            }
        }
    }

    private func loadDailyInsight(for userId: UUID) async {
        if dailyInsight == nil {
            insightState = .loading
        }

        do {
            let fetched = try await contentService.fetchDailyInsight(for: userId)
            guard currentUser?.id == userId else { return }

            dailyInsight = fetched
            insightState = .loaded
        } catch {
            guard currentUser?.id == userId, !error.isCancellation else { return }

            // Yesterday's insight must not stay on screen as today's
            if dailyInsight?.isFromToday != true {
                dailyInsight = nil
                insightState = .failed(error.userMessage)
            }
        }
    }
}
