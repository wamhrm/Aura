//
//  HomeViewModel.swift
//  Aura
//
//  Created by wamhrm on 05.05.2026.
//


import Combine
import Foundation

enum HomeRoutes: Hashable {
    case horoscopeDetails, allTests, testResults, aiConsent
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
    @Published private(set) var loadingTitle: String?
    @Published var emailConfirmation: EmailConfirmationViewModel?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private var coverTask: Task<Void, Never>?

    private static let homeLoadTitle = "Загружаем информацию"

    private var currentUser: UserModel?
    private var personalityRequestID: UUID?
    private var personalityRequestUser: UserModel?
    private var personalityRequestTests: [PersonalityTestTypes]?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService
        loadingTitle = Self.homeLoadTitle

        setupSubscriptions()
    }

    var greetingText: String {
        "Здравствуйте, \(userName.capitalized)"
    }

    private var isHomeReady: Bool {
        let horoscopeReady = horoscope != nil || horoscopeState != .loading
        let insightReady = !allowsAIAnalysis || insightState != .loading
        return horoscopeReady && insightReady
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

        guard let previousUser, previousUser.id == user.id else {
            loadingTitle = Self.homeLoadTitle
            Task { await refresh() }
            return
        }

        if previousUser.dateOfBirth != user.dateOfBirth {
            horoscope = nil
            horoscopeState = .loading
            if coverTask == nil { loadingTitle = Self.homeLoadTitle }
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

    func showAIConsent() {
        guard !homeRoutes.contains(.aiConsent) else { return }
        homeRoutes.append(.aiConsent)
    }

    func allowAIConsent() {
        performCovered("Обновляем информацию") {
            try await self.authService.giveAIConsent()
            try await self.refreshUnlockedContent()
        } commit: {
            self.homeRoutes = []
        }
    }

    func declineAIConsent() {
        homeRoutes = []
    }

    private func refreshUnlockedContent() async throws {
        async let insight = fetchInsight()
        async let tip = fetchDailyTip()
        try await insight
        try await tip
    }

    private func fetchInsight() async throws {
        dailyInsight = try await contentService.fetchDailyInsight()
        insightState = .loaded
    }

    private func fetchDailyTip() async throws {
        guard currentUser?.dateOfBirth != nil else { return }
        _ = try await contentService.fetchDailyTip()
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
        guard coverTask == nil else { return }

        if let currentUser, !currentUser.hasConfirmedEmail {
            emailConfirmation = EmailConfirmationViewModel(authService: authService, email: currentUser.email ?? "")
            return
        }

        let tests = selectedTests
        let requestID = currentPersonalityRequestID()

        performCovered("Готовим результат...") {
            self.personalityResult = try await self.contentService.makePersonalityTest(selectedTests: tests, requestID: requestID)
        } commit: {
            self.homeRoutes.append(.testResults)
        }
    }

    private func performCovered(_ title: String,
                                operation: @escaping () async throws -> Void,
                                commit: @escaping () -> Void = {}) {
        guard coverTask == nil else { return }

        loadingTitle = title
        coverTask = Task {
            defer { self.coverTask = nil }

            do {
                try await CoveredTransition.run(hide: { self.restoreCover() },
                                                operation: operation,
                                                commit: commit)
            } catch {
                self.presentAlert(error.userMessage)
            }
        }
    }

    private func restoreCover() {
        loadingTitle = isHomeReady ? nil : Self.homeLoadTitle
    }

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

        async let horoscopeLoad = loadHoroscope()

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
            if horoscope == nil {
                horoscopeState = .failed(error.userMessage)
            }
        }
        
        try? await Task.sleep(for: .seconds(1))
        revealScreenIfReady()
    }

    private func loadDailyInsight() async {
        guard currentUser?.allowsAIAnalysis == true else { return }

        if dailyInsight?.isFromToday != true {
            dailyInsight = nil
            insightState = .loading
        }

        async let tip = loadDailyTip()
        await fetchInsightQuietly()
        
        try? await Task.sleep(for: .seconds(1))
        revealScreenIfReady()
        await tip
    }

    private func fetchInsightQuietly() async {
        do {
            try await fetchInsight()
        } catch {
            if dailyInsight?.isFromToday != true {
                dailyInsight = nil
                insightState = .failed(error.userMessage)
            }
        }
    }

    private func loadDailyTip() async {
        guard currentUser?.dateOfBirth != nil else { return }
        _ = try? await contentService.fetchDailyTip()
    }

    private func revealScreenIfReady() {
        guard coverTask == nil else { return }
        
        loadingTitle = isHomeReady ? nil : Self.homeLoadTitle
    }
}
