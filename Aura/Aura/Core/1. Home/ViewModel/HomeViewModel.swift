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
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingScreen = true
    @Published private(set) var loadingTitle = ""
    @Published var emailConfirmation: EmailConfirmationViewModel?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol

    private var currentUser: UserModel?
    private var lastRefreshDate: Date?
    private var horoscopeRequestID: UUID?
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
        AppLanguage.text("Здравствуйте, \(userName.capitalized)")
    }

    var showsLoadingScreen: Bool {
        isLoading || (isLoadingScreen && homeRoutes.isEmpty)
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
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                handleAuthState($0)
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
                horoscopeRequestID = nil
                horoscope = nil
                dailyInsight = nil
                cancellables.removeAll()
        }
    }

    private func handleUser(_ user: UserModel) {
        let previousUser = currentUser

        currentUser = user
        allowsAIAnalysis = user.allowsAIAnalysis
        if user.hasConfirmedEmail { emailConfirmation = nil }
        userName = user.name.capitalized

        guard let previousUser, previousUser.id == user.id else {
            isLoadingScreen = true
            Task { await refreshIfNeeded() }
            return
        }

        if previousUser.dateOfBirth != user.dateOfBirth {
            horoscopeRequestID = nil
            horoscope = nil
            horoscopeState = .loading
            if !isLoading { isLoadingScreen = true }
            Task { await loadHoroscope() }
        }

        if !previousUser.allowsAIAnalysis && user.allowsAIAnalysis && !isLoading {
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
        guard !isLoading else { return }
        isLoading = true
        loadingTitle = AppLanguage.text("Обновляем информацию")

        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }

            do {
                try await authService.giveAIConsent()
                guard sessionID == authService.sessionID else { return }
                await loadDailyInsight()
                guard sessionID == authService.sessionID else { return }
                homeRoutes = []
                try await Task.sleep(for: .milliseconds(50))
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
            await revealScreenIfReady()
        }
    }

    func declineAIConsent() {
        homeRoutes = []
    }

    func toggleTestSelection(_ test: PersonalityTestTypes) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > InputLimits.minPersonalityTests else {
                presentAlert(AppLanguage.text("Нельзя выбрать меньше \(InputLimits.minPersonalityTests) тестов"))
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
            emailConfirmation = EmailConfirmationViewModel(authService: authService,
                                                           email: currentUser.email ?? "")
            return
        }

        let tests = selectedTests
        let requestID = currentPersonalityRequestID()
        isLoading = true
        loadingTitle = AppLanguage.text("Готовим результат...")

        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                let result = try await contentService.makePersonalityTest(selectedTests: tests,
                                                                          requestID: requestID)
                guard sessionID == authService.sessionID else { return }
                personalityResult = result
                personalityRequestID = nil
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                homeRoutes.append(.testResults)
                try await Task.sleep(for: .milliseconds(50))
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
            await revealScreenIfReady()
        }
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
        if case .signedIn(let user) = authService.authState { return user }
        return nil
    }

    func refresh() async {
        guard let user = currentUser else { return }
        lastRefreshDate = Date()

        async let horoscopeLoad = loadHoroscope()

        if user.allowsAIAnalysis {
            await loadDailyInsight()
        }

        await horoscopeLoad
    }

    func refreshIfNeeded() async {
        if let lastRefreshDate, Calendar.current.isDateInToday(lastRefreshDate) { return }
        await refresh()
    }

    func retryHoroscope() {
        Task { await loadHoroscope() }
    }

    func retryDailyInsight() {
        Task { await loadDailyInsight() }
    }

    private func loadHoroscope() async {
        guard let user = currentUser else { return }
        let sessionID = authService.sessionID
        let requestID = UUID()
        horoscopeRequestID = requestID
        let deadline = ContinuousClock.now + .seconds(1)
        if horoscope == nil { horoscopeState = .loading }

        func isCurrentRequest() -> Bool {
            requestID == horoscopeRequestID &&
            sessionID == authService.sessionID &&
            user.dateOfBirth == signedInUser?.dateOfBirth
        }

        do {
            let horoscope = try await contentService.fetchCurrentHoroscope()
            guard isCurrentRequest() else { return }
            self.horoscope = horoscope
            horoscopeState = .loaded
        } catch {
            guard isCurrentRequest() else { return }
            if horoscope == nil {
                horoscopeState = .failed(error.userMessage)
            }
        }
        
        try? await Task.sleep(until: deadline, clock: .continuous)
        guard isCurrentRequest() else { return }
        await revealScreenIfReady()
    }

    private func loadDailyInsight() async {
        guard signedInUser?.allowsAIAnalysis == true else { return }
        let sessionID = authService.sessionID
        let deadline = ContinuousClock.now + .seconds(1)

        if dailyInsight?.isFromToday != true {
            dailyInsight = nil
            insightState = .loading
        }

        do {
            let insight = try await contentService.fetchDailyInsight()
            guard sessionID == authService.sessionID else { return }
            dailyInsight = insight
            insightState = .loaded
        } catch {
            guard sessionID == authService.sessionID else { return }
            if dailyInsight?.isFromToday != true {
                dailyInsight = nil
                insightState = .failed(error.userMessage)
            }
        }

        try? await Task.sleep(until: deadline, clock: .continuous)
        guard sessionID == authService.sessionID else { return }
        await revealScreenIfReady()
    }

    private func revealScreenIfReady() async {
        if isLoadingScreen && isHomeReady {
            try? await Task.sleep(for: .milliseconds(350))
        }
        guard !isLoading else { return }
        isLoadingScreen = !isHomeReady
    }
}
