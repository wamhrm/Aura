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
func makeUser(name: String = "Дмитрий",
              dateOfBirth: String? = "13.05.2000",
              socialType: String? = "introvert",
              hasAIConsent: Bool? = true,
              isEmailConfirmed: Bool? = true) -> UserModel {
    UserModel(id: UserModel.mock.id,
              name: name,
              email: "test@test.com",
              dateOfBirth: dateOfBirth,
              birthTime: nil,
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

    @MainActor
    func loadUser() -> UserModel? {
        guard let data = defaults.data(forKey: Constants.userKey) else { return nil }
        return try? JSONDecoder().decode(UserModel.self, from: data)
    }

    @MainActor
    func saveUser(user: UserModel) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        defaults.set(data, forKey: Constants.userKey)
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

    var serverUser = UserModel.mock
    var errorToThrow: (any Error)?
    var aiConsentError: (any Error)?
    var profileSaveDelay = Duration.zero
    private(set) var profileSaveFinished = false

    private(set) var createAccountCount = 0
    private(set) var emailCheckCount = 0
    var emailTaken = false
    private(set) var resetPasswordCount = 0
    private(set) var aiConsentCount = 0
    private(set) var confirmedCode: String?
    private(set) var savedProfile: ProfileInfoModel?
    private(set) var showsMainScreen = false
    private(set) var didAskAIConsent = false
    private var expiredSessionMessage: String?

    init(user: UserModel? = nil) {
        if let user {
            authState = CurrentValueSubject(.signedIn(user))
        } else {
            authState = CurrentValueSubject(.signedOut)
        }
    }

    func noteAIConsentAsked() {
        didAskAIConsent = true
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

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        savedProfile = request
        defer { profileSaveFinished = true }
        try await Task.sleep(for: profileSaveDelay)
        if let errorToThrow { throw errorToThrow }
        authState.send(.signedIn(serverUser))
        return UpdateProfileInfoResponse(user: serverUser, horoscope: .mock)
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
        didAskAIConsent = false
        authState.send(.signedOut)
    }

    func endExpiredSession() {
        expiredSessionMessage = "Сессия истекла. Войдите снова"
        showsMainScreen = false
        didAskAIConsent = false
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
        didAskAIConsent = false
        authState.send(.signedOut)
    }

    private func startSession() throws {
        if let errorToThrow { throw errorToThrow }
        authState.send(.signedIn(serverUser))
    }
}

@MainActor
final class MockContentService: ContentServiceProtocol {
    let historyCells = CurrentValueSubject<[HistoryCellModel], Never>([])
    let horoscope = CurrentValueSubject<HoroscopeModel?, Never>(nil)
    let dailyInsight = CurrentValueSubject<DailyContentModel?, Never>(nil)
    let dailyTip = CurrentValueSubject<DailyContentModel?, Never>(nil)

    var history: [HistoryCellModel] = []
    var errorToThrow: (any Error)?
    var dailyContentDate = todayText()
    var beforeContentResponse: (() -> Void)?

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
        beforeContentResponse?()
        if let errorToThrow { throw errorToThrow }
        historyCells.send(history)
        return history
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        if let errorToThrow { throw errorToThrow }
        return historyDetails(id: id)
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
