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
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, userDefaults: storage.defaults)

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
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

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
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        keychain.deleteFails = true

        do {
            try await auth.signOut()
            XCTFail("Sign-out must fail")
        } catch {
            XCTAssertEqual((error as? KeychainError)?.status, errSecInteractionNotAllowed)
        }

        XCTAssertEqual(try keychain.loadAuthToken(), "new-token")
        XCTAssertEqual(storage.loadUser(), network.user)
        guard case .signedIn = auth.authState.value else { return XCTFail("Failed sign-out ended the session") }
    }

    func test_successfulSignOut_removesTokenAndSavedUser() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")

        try await auth.signOut()

        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.loadUser())
        guard case .signedOut = auth.authState.value else { return XCTFail("Session was not ended") }
    }

    func test_tokenWithoutSavedUser_staysSignedOut() throws {
        // Given
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        let storage = makeStorage()
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, userDefaults: storage.defaults)

        // Then
        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")
        XCTAssertNil(storage.loadUser())
        guard case .signedOut = auth.authState.value else { return XCTFail("Token alone opened a session") }
        XCTAssertFalse(auth.showsMainScreen)
    }

    func test_unavailableKeychain_keepsSavedUser_andStaysSignedOut() throws {
        // Given
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        keychain.readFails = true
        let storage = makeStorage()
        let user = makeUser()
        storage.saveUser(user: user)

        // When
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, userDefaults: storage.defaults)

        // Then
        XCTAssertEqual(storage.loadUser(), user)
        guard case .signedOut = auth.authState.value else { return XCTFail("Unreadable token opened a session") }
        XCTAssertFalse(auth.showsMainScreen)
    }

    func test_launch_showsMainScreen_onlyWithACompleteProfile() throws {
        // Given / When
        let complete = try makeStoredAuth(user: makeUser())
        let incomplete = try makeStoredAuth(user: makeUser(dateOfBirth: nil))
        let signedOut = try makeStoredAuth(user: nil)

        // Then
        XCTAssertTrue(complete.showsMainScreen)
        XCTAssertFalse(incomplete.showsMainScreen)
        XCTAssertFalse(signedOut.showsMainScreen)
    }

    func test_signIn_staysInOnboarding_untilItFinishes() async throws {
        // Given
        let auth = try makeStoredAuth(user: nil)

        // When
        try await auth.signIn(email: "test@test.com", password: "password")

        // Then
        XCTAssertFalse(auth.showsMainScreen)

        // When the onboarding flow finishes
        auth.finishOnboarding()

        // Then
        XCTAssertTrue(auth.showsMainScreen)
        auth.noteAIConsentAsked()
        XCTAssertTrue(auth.didAskAIConsent)
        try await auth.signOut()
        XCTAssertFalse(auth.showsMainScreen)
        XCTAssertFalse(auth.didAskAIConsent)
    }

    private func makeStoredAuth(user: UserModel?) throws -> AuthService {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()

        if let user {
            try keychain.saveAuthToken("saved-token")
            storage.saveUser(user: user)
            network.user = user
        }

        return AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
    }

    func test_profileConsentAndConfirmation_saveTheUserFromTheServer() async throws {
        // Given
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")

        // When the profile is saved
        let saved = makeUser(dateOfBirth: "20.01.1990", hasAIConsent: false, isEmailConfirmed: false)
        network.user = saved
        _ = try await auth.updateProfileInfo(ProfileInfoModel())

        // Then
        XCTAssertEqual(storage.loadUser(), saved)

        // When consent and confirmation return the next user
        let confirmed = makeUser(dateOfBirth: "01.01.2001", hasAIConsent: true, isEmailConfirmed: true)
        network.user = confirmed
        try await auth.giveAIConsent()
        try await auth.confirmEmail(code: "123456")

        // Then
        XCTAssertEqual(storage.loadUser(), confirmed)
        guard case .signedIn(let user) = auth.authState.value else { return XCTFail("No session") }
        XCTAssertEqual(user, confirmed)
    }

    func test_rejectedToken_endsTheLocalSessionWithoutLogout() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        auth.noteAIConsentAsked()
        auth.finishOnboarding()
        network.errorToThrow = NetworkError.sessionExpired

        do {
            _ = try await auth.updateProfileInfo(ProfileInfoModel())
            XCTFail("The request must fail")
        } catch NetworkError.sessionExpired {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(network.logoutCount, 0)
        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.loadUser())
        XCTAssertFalse(auth.showsMainScreen)
        XCTAssertFalse(auth.didAskAIConsent)
        guard case .signedOut = auth.authState.value else { return XCTFail("Session was not ended") }
        XCTAssertEqual(auth.takeExpiredSessionMessage(), "Сессия истекла. Войдите снова")
    }

    func test_serverError_keepsTheLocalSession() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        network.errorToThrow = NetworkError.server("Ошибка сервера")

        do {
            _ = try await auth.updateProfileInfo(ProfileInfoModel())
            XCTFail("The request must fail")
        } catch let error as NetworkError {
            guard case .server = error else { return XCTFail("Unexpected error: \(error)") }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(try keychain.loadAuthToken(), "new-token")
        XCTAssertEqual(storage.loadUser(), network.user)
        guard case .signedIn = auth.authState.value else { return XCTFail("A server error ended the session") }
    }

    func test_contentRequest_withRejectedToken_endsTheLocalSession() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        auth.finishOnboarding()
        let content = ContentService(networkService: network, authService: auth)
        network.errorToThrow = NetworkError.sessionExpired

        do {
            _ = try await content.fetchHistory()
            XCTFail("The request must fail")
        } catch NetworkError.sessionExpired {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(network.logoutCount, 0)
        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.loadUser())
        XCTAssertFalse(auth.showsMainScreen)
        guard case .signedOut = auth.authState.value else { return XCTFail("Session was not ended") }
    }
}

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
    var user = makeUser()
    var history: [HistoryCellModel] = []
    var errorToThrow: (any Error)?
    var beforeHistoryResponse: (() async throws -> Void)?
    private(set) var logoutCount = 0

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        AuthTokenResponse(token: "new-token", user: user)
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        if let errorToThrow { throw errorToThrow }
        return UpdateProfileInfoResponse(user: user, horoscope: nil)
    }

    func giveAIConsent() async throws -> UserModel {
        user
    }

    func confirmEmail(code: String) async throws -> UserModel {
        user
    }

    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse { throw serverError }
    func ensureEmailAvailable(email: String) async throws {}
    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse { throw serverError }
    func logout() async throws {
        logoutCount += 1
        throw serverError
    }
    func deleteAccount() async throws { throw serverError }
    func requestPasswordReset(email: String) async throws { throw serverError }
    func sendEmailConfirmationCode() async throws { throw serverError }
    func fetchCurrentHoroscope() async throws -> HoroscopeModel { throw serverError }
    func fetchDailyInsight() async throws -> DailyContentModel { throw serverError }
    func fetchDailyTip() async throws -> DailyContentModel { throw serverError }
    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel { throw serverError }
    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel { throw serverError }
    func fetchHistory() async throws -> [HistoryCellModel] {
        if let errorToThrow { throw errorToThrow }
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
