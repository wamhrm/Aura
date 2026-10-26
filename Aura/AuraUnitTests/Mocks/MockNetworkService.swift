//
//  MockNetworkService.swift
//  AuraUnitTests
//

import Foundation
@testable import Aura

@MainActor
final class MockNetworkService: NetworkServiceProtocol {
    let sessionExpiredEvents = AsyncStream<Void> { _ in }

    var authTokenResponse = AuthTokenResponse(token: "test-token", user: .mock)
    var updateProfileInfoResponse = UpdateProfileInfoResponse(user: .mock, horoscope: .mock)
    var errorToThrow: Error?

    private(set) var createAccountCallCount = 0
    private(set) var signInCallCount = 0
    private(set) var logoutCallCount = 0

    func createAccount(name: String, email: String, password: String) async throws {
        createAccountCallCount += 1
        if let errorToThrow { throw errorToThrow }
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        signInCallCount += 1
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
        logoutCallCount += 1
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
        return MockContentService.dailyContent
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        if let errorToThrow { throw errorToThrow }
        return MockContentService.dailyContent
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest) async throws -> CompabilityResultModel {
        if let errorToThrow { throw errorToThrow }
        return .mock
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        if let errorToThrow { throw errorToThrow }
        return []
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        if let errorToThrow { throw errorToThrow }
        return .compatibilityPlaceholder
    }

    func deleteHistory(id: UUID) async throws {
        if let errorToThrow { throw errorToThrow }
    }
}
