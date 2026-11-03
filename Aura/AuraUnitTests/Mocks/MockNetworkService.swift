//
//  MockNetworkService.swift
//  AuraUnitTests
//

import Foundation
@testable import Aura

@MainActor
final class MockNetworkService: NetworkServiceProtocol {
    let sessionExpiredEvents: AsyncStream<String>
    let sessionExpiredContinuation: AsyncStream<String>.Continuation

    var authTokenResponse = AuthTokenResponse(token: "test-token", user: .mock)
    var updateProfileInfoResponse = UpdateProfileInfoResponse(user: .mock, horoscope: .mock)
    var errorToThrow: Error?
    var historyToReturn: [HistoryCellModel] = []
    var historyDelay: Duration?
    var sentRequestIDs: [UUID] = []

    private(set) var fetchHistoryCallCount = 0

    init() {
        (sessionExpiredEvents, sessionExpiredContinuation) = AsyncStream.makeStream(of: String.self)
    }

    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse {
        if let errorToThrow { throw errorToThrow }
        return authTokenResponse
    }

    func fetchCurrentUser() async throws -> UserModel {
        if let errorToThrow { throw errorToThrow }
        return authTokenResponse.user
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        if let errorToThrow { throw errorToThrow }
        return authTokenResponse
    }

    func signInWithApple(identityToken: String,
                         authorizationCode: String?,
                         nonce: String,
                         name: String?) async throws -> AuthTokenResponse {
        if let errorToThrow { throw errorToThrow }
        return authTokenResponse
    }

    func logout(token: String) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func requestPasswordReset(email: String) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse {
        if let errorToThrow { throw errorToThrow }
        return authTokenResponse
    }

    func deleteAccount() async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func giveAIConsent() async throws -> UserModel {
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func sendEmailConfirmationCode() async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func confirmEmail(code: String) async throws -> UserModel {
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        if let errorToThrow { throw errorToThrow }
        return updateProfileInfoResponse
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        if let errorToThrow { throw errorToThrow }
        return DailyContentModel(id: UUID(), text: "tip", dateCreated: "2026-01-01")
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        if let errorToThrow { throw errorToThrow }
        return DailyContentModel(id: UUID(), text: "tip", dateCreated: "2026-01-01")
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel {
        sentRequestIDs.append(requestID)
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompabilityResultModel {
        sentRequestIDs.append(requestID)
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        fetchHistoryCallCount += 1
        let history = historyToReturn
        if let historyDelay { try await Task.sleep(for: historyDelay) }
        if let errorToThrow { throw errorToThrow }
        return history
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        if let errorToThrow { throw errorToThrow }
        return .compatibilityPlaceholder
    }

    func deleteHistory(id: UUID) async throws {
        if let errorToThrow { throw errorToThrow }
    }
}
