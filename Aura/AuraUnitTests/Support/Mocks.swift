//
//  Mocks.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import Combine
import Foundation
import XCTest
@testable import Aura

let serverError = NetworkError.server("Ошибка сервера")

@MainActor
func waitUntil(file: StaticString = #filePath, line: UInt = #line, _ condition: () -> Bool) async {
    for _ in 0..<300 {
        if condition() { return }
        try? await Task.sleep(for: .milliseconds(10))
    }

    XCTFail("The expected state did not appear within 3 seconds", file: file, line: line)
}

@MainActor
func makeUser(id: UUID = UserModel.mock.id,
              name: String = "Дмитрий",
              dateOfBirth: String? = "13.05.2000",
              gender: String? = "man",
              socialType: String? = "introvert",
              hasAIConsent: Bool? = true,
              isEmailConfirmed: Bool? = true) -> UserModel {
    UserModel(id: id,
              name: name,
              email: "test@test.com",
              dateOfBirth: dateOfBirth,
              birthTime: nil,
              gender: gender,
              socialType: socialType,
              conflictStyle: "mediator",
              emotionalCore: "logic",
              decisionStyle: "planner",
              coreFocus: "stability",
              hasAIConsent: hasAIConsent,
              isEmailConfirmed: isEmailConfirmed)
}

final class TestDefaults {
    let defaults: UserDefaults
    private let suite: String

    init() {
        suite = "aura-tests." + UUID().uuidString
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    deinit {
        defaults.removePersistentDomain(forName: suite)
    }
}

func makeStorage() -> TestDefaults {
    TestDefaults()
}

func todayText() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
}

@MainActor
final class MockAuthService: AuthServiceProtocol {
    let authState: CurrentValueSubject<AuthState, Never>
    private(set) var sessionID: UUID?

    var serverUser = UserModel.mock
    var errorToThrow: (any Error)?
    var aiConsentError: (any Error)?
    var profileSaveDelay = Duration.zero
    private(set) var profileSaveFinished = false

    private(set) var createAccountCount = 0
    private(set) var emailCheckCount = 0
    var emailTaken = false
    var beforeEmailResponse: (() -> Void)?
    private(set) var resetPasswordCount = 0
    private(set) var aiConsentCount = 0
    private(set) var confirmedCode: String?
    private(set) var savedProfile: ProfileInfoModel?
    private(set) var showsMainScreen = false
    private var expiredSessionMessage: String?

    init(user: UserModel? = nil) {
        if let user {
            sessionID = UUID()
            authState = CurrentValueSubject(.signedIn(user))
        } else {
            authState = CurrentValueSubject(.signedOut)
        }
    }

    func finishOnboarding() {
        guard case .signedIn(let user) = authState.value, user.hasCompletedProfileInfo else { return }
        showsMainScreen = true
    }

    func createAccount(name: String, email: String, password: String) async throws {
        createAccountCount += 1
        try startSession()
    }

    func ensureEmailAvailable(email: String) async throws {
        emailCheckCount += 1
        beforeEmailResponse?()
        if emailTaken { throw NetworkError.userExists }
    }

    func signIn(email: String, password: String) async throws {
        try startSession()
    }

    func requestPasswordReset(email: String) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        resetPasswordCount += 1
        try startSession()
    }

    func updateProfileInfo(_ request: ProfileInfoModel) async throws {
        let sessionID = sessionID
        savedProfile = request
        defer { profileSaveFinished = true }
        try await Task.sleep(for: profileSaveDelay)
        guard sessionID == self.sessionID else { throw NetworkError.cancelled }
        if let errorToThrow { throw errorToThrow }
        authState.send(.signedIn(serverUser))
    }

    func giveAIConsent() async throws {
        aiConsentCount += 1
        if let aiConsentError { throw aiConsentError }
        if let errorToThrow { throw errorToThrow }
        serverUser.hasAIConsent = true
        authState.send(.signedIn(serverUser))
    }

    func sendEmailConfirmationCode() async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func confirmEmail(code: String) async throws {
        confirmedCode = code
        if let errorToThrow { throw errorToThrow }
    }

    func signOut() async throws {
        if let errorToThrow { throw errorToThrow }
        showsMainScreen = false
        sessionID = nil
        authState.send(.signedOut)
    }

    func endExpiredSession() {
        expiredSessionMessage = "Сессия истекла. Войдите снова"
        showsMainScreen = false
        sessionID = nil
        authState.send(.signedOut)
    }

    func takeExpiredSessionMessage() -> String? {
        let message = expiredSessionMessage
        expiredSessionMessage = nil
        return message
    }

    func deleteAccount() async throws {
        if let errorToThrow { throw errorToThrow }
        showsMainScreen = false
        sessionID = nil
        authState.send(.signedOut)
    }

    private func startSession() throws {
        if let errorToThrow { throw errorToThrow }
        sessionID = UUID()
        authState.send(.signedIn(serverUser))
    }
}

@MainActor
final class MockContentService: ContentServiceProtocol {
    let historyCells = CurrentValueSubject<[HistoryCellModel], Never>([])
    let historyState = CurrentValueSubject<LoadState, Never>(.loaded)
    let horoscope = CurrentValueSubject<HoroscopeModel?, Never>(nil)
    let dailyInsight = CurrentValueSubject<DailyContentModel?, Never>(nil)
    let dailyTip = CurrentValueSubject<DailyContentModel?, Never>(nil)

    var history: [HistoryCellModel] = []
    var errorToThrow: (any Error)?
    var dailyContentDate = todayText()
    var horoscopeDelay = Duration.zero
    var beforeContentResponse: (() -> Void)?
    var beforeDetailsResponse: (() -> Void)?
    private(set) var detailsCount = 0

    private(set) var personalityRequestIDs: [UUID] = []
    private(set) var compatibilityRequests: [CompatibilityTestRequest] = []
    private(set) var compatibilityRequestIDs: [UUID] = []
    private(set) var fetchHistoryCount = 0
    private(set) var horoscopeCount = 0
    private(set) var insightCount = 0
    private(set) var tipCount = 0

    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel {
        personalityRequestIDs.append(requestID)
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel {
        compatibilityRequests.append(request)
        compatibilityRequestIDs.append(requestID)
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        fetchHistoryCount += 1
        if historyCells.value.isEmpty { historyState.send(.loading) }
        beforeContentResponse?()
        if let errorToThrow {
            if historyCells.value.isEmpty { historyState.send(.failed(errorToThrow.userMessage)) }
            throw errorToThrow
        }
        historyState.send(.loaded)
        historyCells.send(history)
        return history
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        detailsCount += 1
        let details = historyDetails(id: id)
        beforeDetailsResponse?()
        if let errorToThrow { throw errorToThrow }
        return details
    }

    func deleteHistory(id: UUID) async throws {
        if let errorToThrow { throw errorToThrow }
        history.removeAll { $0.id == id }
        historyCells.send(history)
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        insightCount += 1
        beforeContentResponse?()
        if let errorToThrow { throw errorToThrow }
        let insight = DailyContentModel(id: UUID(), text: "Инсайт", dateCreated: dailyContentDate)
        dailyInsight.send(insight)
        return insight
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        tipCount += 1
        beforeContentResponse?()
        if let errorToThrow { throw errorToThrow }
        let tip = DailyContentModel(id: UUID(), text: "Совет", dateCreated: dailyContentDate)
        dailyTip.send(tip)
        return tip
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        horoscopeCount += 1
        try await Task.sleep(for: horoscopeDelay)
        if let errorToThrow { throw errorToThrow }
        horoscope.send(.mock)
        return .mock
    }

    private func historyDetails(id: UUID) -> HistoryCellModel {
        let cell = history.first { $0.id == id } ?? .personalityPlaceholder
        return HistoryCellModel(id: cell.id,
                                kind: cell.kind,
                                createdAt: cell.createdAt,
                                selectedTests: cell.selectedTests,
                                archetypeTitle: cell.archetypeTitle,
                                archetypeSubtitle: cell.archetypeSubtitle,
                                zodiacSign: cell.zodiacSign,
                                compatibilityScore: cell.compatibilityScore,
                                partnerName: cell.partnerName,
                                partnerZodiacSign: cell.partnerZodiacSign,
                                personalityResult: cell.kind == .personality ? .mock : nil,
                                compatibilityResult: cell.compatibilityResult)
    }
}
