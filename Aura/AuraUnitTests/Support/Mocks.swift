//
//  Mocks.swift
//  AuraUnitTests
//

import Combine
import Foundation
@testable import Aura

let serverError = NetworkError.server("Ошибка сервера")

// View models work in a Task, so a test waits until the result appears.
// If it never does, the checks under "Then" fail.
@MainActor
func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<300 {
        if condition() { return }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

// A filled profile by default, a test changes only what it checks
@MainActor
func makeUser(dateOfBirth: String? = "13.05.2000",
              gender: String? = "man",
              hasAIConsent: Bool? = true,
              isEmailConfirmed: Bool? = true) -> UserModel {
    UserModel(id: UserModel.mock.id,
              name: "Дмитрий",
              email: "test@test.com",
              dateOfBirth: dateOfBirth,
              birthTime: nil,
              gender: gender,
              socialType: "introvert",
              conflictStyle: "mediator",
              emotionalCore: "logic",
              decisionStyle: "planner",
              coreFocus: "stability",
              hasAIConsent: hasAIConsent,
              isEmailConfirmed: isEmailConfirmed)
}

// Keeps a test's files away from the app's own storage
@MainActor
func makeStorage() -> LocalStorage {
    LocalStorage(baseURL: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory))
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

    // Who the server signs in
    var serverUser = UserModel.mock
    var errorToThrow: (any Error)?

    private(set) var createAccountCount = 0
    private(set) var resetPasswordCount = 0
    private(set) var aiConsentCount = 0
    private(set) var refreshUserCount = 0
    private(set) var confirmedCode: String?
    private(set) var savedProfile: ProfileInfoModel?

    init(user: UserModel? = nil) {
        if let user {
            authState = CurrentValueSubject(.signedIn(user))
        } else {
            authState = CurrentValueSubject(.signedOut)
        }
    }

    func createAccount(name: String, email: String, password: String) async throws {
        createAccountCount += 1
        try startSession()
    }

    func signIn(email: String, password: String) async throws {
        try startSession()
    }

    func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) async throws {
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
        if let errorToThrow { throw errorToThrow }
        return UpdateProfileInfoResponse(user: serverUser, horoscope: .mock)
    }

    func giveAIConsent() async throws {
        aiConsentCount += 1
        if let errorToThrow { throw errorToThrow }
    }

    func sendEmailConfirmationCode() async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func confirmEmail(code: String) async throws {
        confirmedCode = code
        if let errorToThrow { throw errorToThrow }
    }

    func signOut() {
        authState.send(.signedOut)
    }

    func deleteAccount() async throws {
        if let errorToThrow { throw errorToThrow }
        authState.send(.signedOut)
    }

    func refreshUser() {
        refreshUserCount += 1
    }

    func restoreSessionIfNeeded() { }

    private func startSession() throws {
        if let errorToThrow { throw errorToThrow }
        authState.send(.signedIn(serverUser))
    }
}

@MainActor
final class MockContentService: ContentServiceProtocol {
    let historyDidChange = PassthroughSubject<Void, Never>()
    let refreshRequested = PassthroughSubject<Void, Never>()

    var history: [HistoryCellModel] = []
    var errorToThrow: (any Error)?

    private(set) var compatibilityRequests: [CompatibilityTestRequest] = []
    private(set) var fetchHistoryCount = 0
    private(set) var horoscopeCount = 0
    private(set) var insightCount = 0

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func makeCompatibilityTest(request: CompatibilityTestRequest) async throws -> CompatibilityResultModel {
        compatibilityRequests.append(request)
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        fetchHistoryCount += 1
        if let errorToThrow { throw errorToThrow }
        return history
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        if let errorToThrow { throw errorToThrow }
        return .personalityPlaceholder
    }

    func deleteHistory(id: UUID) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func fetchDailyInsight(for userId: UUID) async throws -> DailyContentModel {
        insightCount += 1
        if let errorToThrow { throw errorToThrow }
        return DailyContentModel(id: UUID(), text: "Инсайт", dateCreated: todayText())
    }

    func fetchDailyTip(for userId: UUID) async throws -> DailyContentModel {
        if let errorToThrow { throw errorToThrow }
        return DailyContentModel(id: UUID(), text: "Совет", dateCreated: todayText())
    }

    func fetchCurrentHoroscope(for userId: UUID) async throws -> HoroscopeModel {
        horoscopeCount += 1
        if let errorToThrow { throw errorToThrow }
        return .mock
    }
}
