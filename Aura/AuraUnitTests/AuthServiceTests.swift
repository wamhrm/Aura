//
//  AuthServiceTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 06.11.2026.
//

import Combine
import Foundation
import Security
import XCTest
@testable import Aura

@MainActor
final class AuthServiceTests: XCTestCase {
    func test_failedTokenSave_doesNotSignInOrSaveUser() async {
        // Given
        let keychain = MockKeychainHelper()
        keychain.saveFails = true
        let storage = makeStorage()
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, storage: storage)

        // When
        do {
            try await auth.signIn(email: "test@test.com", password: "password")
            XCTFail("Saving the token must fail")
        } catch {
            XCTAssertEqual((error as? KeychainError)?.status, errSecInteractionNotAllowed)
            XCTAssertEqual(error.userMessage, "Данные входа недоступны. Разблокируйте устройство и попробуйте ещё раз")
        }

        // Then
        guard case .signedOut = auth.authState.value else { return XCTFail("Unexpected signed-in session") }
        XCTAssertNil(storage.loadUser())
    }

    func test_successfulSignIn_savesTokenAndUser() async throws {
        // Given
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, storage: storage)

        // When
        try await auth.signIn(email: "test@test.com", password: "password")

        // Then
        XCTAssertEqual(try keychain.loadAuthToken(), "new-token")
        XCTAssertEqual(storage.loadUser(), network.user)
        guard case .signedIn(let user) = auth.authState.value else { return XCTFail("No session") }
        XCTAssertEqual(user, network.user)
    }

    func test_failedTokenDeletion_keepsSessionAndSavedUser() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, storage: storage)
        try await auth.signIn(email: "test@test.com", password: "password")
        keychain.deleteFails = true

        XCTAssertThrowsError(try auth.signOut()) { error in
            XCTAssertEqual((error as? KeychainError)?.status, errSecInteractionNotAllowed)
        }

        XCTAssertEqual(try keychain.loadAuthToken(), "new-token")
        XCTAssertEqual(storage.loadUser(), network.user)
        guard case .signedIn = auth.authState.value else { return XCTFail("Failed sign-out ended the session") }
    }

    func test_successfulSignOut_removesTokenAndSavedUser() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, storage: storage)
        try await auth.signIn(email: "test@test.com", password: "password")

        try auth.signOut()

        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.loadUser())
        guard case .signedOut = auth.authState.value else { return XCTFail("Session was not ended") }
    }

    func test_missingUserFile_restoresUserThroughMe() async throws {
        // Given
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, storage: storage)

        // When
        await auth.restoreSessionIfNeeded()

        // Then
        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")
        XCTAssertEqual(storage.loadUser(), network.user)
        XCTAssertEqual(network.fetchCount, 1)
        guard case .signedIn(let user) = auth.authState.value else { return XCTFail("Session was not restored") }
        XCTAssertEqual(user, network.user)
    }

    func test_unavailableKeychain_preservesSavedData_andRestoresAfterUnlock() async throws {
        // Given
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        keychain.readFails = true
        let storage = makeStorage()
        storage.saveUser(user: makeUser())
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, storage: storage)

        // When
        await auth.restoreSessionIfNeeded()

        // Then
        XCTAssertNotNil(storage.loadUser())
        XCTAssertEqual(network.fetchCount, 0)

        // When access becomes available
        keychain.readFails = false
        await auth.restoreSessionIfNeeded()

        // Then
        guard case .signedIn = auth.authState.value else { return XCTFail("Session was not restored") }
        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")
    }

    func test_consentAndConfirmation_doNotReplaceCurrentProfile() async throws {
        // Given
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        network.user = makeUser(hasAIConsent: false, isEmailConfirmed: false)
        let auth = AuthService(networkService: network, keychain: keychain, storage: storage)
        try await auth.signIn(email: "test@test.com", password: "password")
        network.user = makeUser(dateOfBirth: "20.01.1990", hasAIConsent: false, isEmailConfirmed: false)
        _ = try await auth.updateProfileInfo(ProfileInfoModel())

        // When the endpoints return an older profile
        network.user = makeUser()
        try await auth.giveAIConsent()
        try await auth.confirmEmail(code: "123456")

        // Then
        XCTAssertEqual(storage.loadUser()?.dateOfBirth, "20.01.1990")
        XCTAssertEqual(storage.loadUser()?.hasAIConsent, true)
        XCTAssertEqual(storage.loadUser()?.isEmailConfirmed, true)
    }
}

// These tests access the in-memory Keychain only on MainActor.
private nonisolated final class MockKeychainHelper: KeychainHelperProtocol, @unchecked Sendable {
    var data: Data?
    var saveFails = false
    var readFails = false
    var deleteFails = false

    func saveToken(_ data: Data, path: String, key: String) throws {
        if saveFails { throw KeychainError(status: errSecInteractionNotAllowed) }
        self.data = data
    }

    func getToken(path: String, key: String) throws -> Data? {
        if readFails { throw KeychainError(status: errSecInteractionNotAllowed) }
        return data
    }

    func deleteToken(path: String, key: String) throws {
        if deleteFails { throw KeychainError(status: errSecInteractionNotAllowed) }
        data = nil
    }
}

@MainActor
final class MockNetworkService: NetworkServiceProtocol {
    nonisolated let sessionExpiredEvents = AsyncStream<String> { $0.finish() }
    var user = makeUser()
    var fetchCount = 0
    var history: [HistoryCellModel] = []
    var beforeHistoryResponse: (() async throws -> Void)?

    func fetchCurrentUser() async throws -> UserModel {
        fetchCount += 1
        return user
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        AuthTokenResponse(token: "new-token", user: user)
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        UpdateProfileInfoResponse(user: user, horoscope: nil)
    }

    func giveAIConsent() async throws -> UserModel {
        user
    }

    func confirmEmail(code: String) async throws -> UserModel {
        user
    }

    // Other requirements of the existing network protocol.
    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse { throw serverError }
    func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) async throws -> AuthTokenResponse { throw serverError }
    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse { throw serverError }
    func logout(token: String) async throws { throw serverError }
    func deleteAccount() async throws { throw serverError }
    func requestPasswordReset(email: String) async throws { throw serverError }
    func sendEmailConfirmationCode() async throws { throw serverError }
    func fetchCurrentHoroscope() async throws -> HoroscopeModel { throw serverError }
    func fetchDailyInsight() async throws -> DailyContentModel { throw serverError }
    func fetchDailyTip() async throws -> DailyContentModel { throw serverError }
    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel { throw serverError }
    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel { throw serverError }
    func fetchHistory() async throws -> [HistoryCellModel] {
        let response = history
        try await beforeHistoryResponse?()
        return response
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await beforeHistoryResponse?()
        return .personalityPlaceholder
    }

    func deleteHistory(id: UUID) async throws {
        history.removeAll { $0.id == id }
    }
}
