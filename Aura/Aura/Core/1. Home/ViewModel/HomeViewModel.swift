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
    @Published var emailConfirmation: EmailConfirmationViewModel?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var currentUser: UserModel?
    private var personalityRequestID: UUID?
    private var personalityRequestUser: UserModel?
    private var personalityRequestTests: [PersonalityTestTypes]?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

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

        contentService.horoscope
            .receive(on: DispatchQueue.main)
            .sink { [weak self] horoscope in
                guard let self else { return }
                self.horoscope = horoscope
                if horoscope != nil { horoscopeState = .loaded }
            }
            .store(in: &cancellables)

        contentService.dailyInsight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] insight in
                guard let self else { return }
                dailyInsight = insight
                if insight != nil { insightState = .loaded }
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
        if user.hasConfirmedEmail { emailConfirmation = nil }
        userName = user.name
        isLoadingScreen = false

        guard let previousUser, previousUser.id == user.id else {
            Task { await refresh() }
            return
        }

        if previousUser.dateOfBirth != user.dateOfBirth {
            horoscope = nil
            horoscopeState = .loading
            Task { await loadHoroscope() }
        }

        if !previousUser.allowsAIAnalysis && user.allowsAIAnalysis {
            Task { await loadDailyInsight() }
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

        if let currentUser, !currentUser.hasConfirmedEmail {
            emailConfirmation = EmailConfirmationViewModel(authService: authService, email: currentUser.email ?? "")
            return
        }

        let tests = selectedTests
        let requestID = currentPersonalityRequestID()
        isLoading = true

        Task {
            do {
                personalityResult = try await contentService.makePersonalityTest(selectedTests: tests,
                                                                                 requestID: requestID)
                homeRoutes.append(.testResults)
            } catch {
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }

    // The same answers retry one server request. A new selection or profile starts another.
    private func currentPersonalityRequestID() -> UUID {
        let user = signedInUser

        if let personalityRequestID,
           personalityRequestUser == user,
           personalityRequestTests == selectedTests {
            return personalityRequestID
        }

        let requestID = UUID()
        personalityRequestID = requestID
        personalityRequestUser = user
        personalityRequestTests = selectedTests
        return requestID
    }

    private var signedInUser: UserModel? {
        if case .signedIn(let user) = authService.authState.value { return user }
        return nil
    }

    func refresh() async {
        guard let user = currentUser else { return }

        async let horoscopeLoad: Void = loadHoroscope()

        if user.allowsAIAnalysis {
            await loadDailyInsight()
        }

        await horoscopeLoad
    }

    func retryHoroscope() {
        Task { await loadHoroscope() }
    }

    func retryDailyInsight() {
        Task { await loadDailyInsight() }
    }

    private func loadHoroscope() async {
        guard currentUser != nil else { return }
        if horoscope == nil { horoscopeState = .loading }

        do {
            horoscope = try await contentService.fetchCurrentHoroscope()
            horoscopeState = .loaded
        } catch {
            guard !error.isCancellation else { return }
            if horoscope == nil {
                horoscopeState = .failed(error.userMessage)
            }
        }
    }

    private func loadDailyInsight() async {
        guard currentUser?.allowsAIAnalysis == true else { return }

        if dailyInsight?.isFromToday != true {
            dailyInsight = nil
            insightState = .loading
        }

        do {
            dailyInsight = try await contentService.fetchDailyInsight()
            insightState = .loaded
        } catch {
            guard !error.isCancellation else { return }
            if dailyInsight?.isFromToday != true {
                dailyInsight = nil
                insightState = .failed(error.userMessage)
            }
        }
    }
}
