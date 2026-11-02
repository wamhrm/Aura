//
//  AuthServiceTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class AuthServiceTests: XCTestCase {
    func test_signIn_savesTokenAndUserAndEmitsSignedIn() async throws {
        // Given
        let keychain = MockKeychain()
        let network = MockNetworkService()
        let storage = MockLocalStorage()
        let sut = makeSUT(keychain: keychain, network: network, storage: storage)

        // When
        try await sut.signIn(email: "a@b.com", password: "123456")

        // Then
        XCTAssertNotNil(keychain.getToken(path: "", key: ""))
        XCTAssertNotNil(storage.loadUser())
        guard case .signedIn(let user) = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
        XCTAssertEqual(user, network.authTokenResponse.user)
    }

    func test_signOut_clearsTokenAndUserAndEmitsSignedOut() async throws {
        // Given
        let keychain = MockKeychain()
        let storage = MockLocalStorage()
        let sut = makeSUT(keychain: keychain, storage: storage)
        try await sut.signIn(email: "a@b.com", password: "123456")

        // When
        sut.signOut()

        // Then
        XCTAssertNil(keychain.getToken(path: "", key: ""))
        XCTAssertNil(storage.loadUser())
        guard case .signedOut = sut.authState.value else {
            return XCTFail("Ожидался signedOut")
        }
    }

    func test_createAccount_startsSessionWithoutSeparateSignIn() async throws {
        // Given
        let network = MockNetworkService()
        let sut = makeSUT(network: network)

        // When
        try await sut.createAccount(name: "Имя", email: "a@b.com", password: "123456")

        // Then
        XCTAssertEqual(network.createAccountCallCount, 1)
        XCTAssertEqual(network.signInCallCount, 0)
        guard case .signedIn = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
    }

    func test_updateProfileInfo_savesUserEmitsSignedInAndReturnsResponse() async throws {
        // Given
        let network = MockNetworkService()
        let storage = MockLocalStorage()
        let sut = makeSUT(network: network, storage: storage)
        try await sut.signIn(email: "a@b.com", password: "123456")

        // When
        let response = try await sut.updateProfileInfo(ProfileInfoModel())

        // Then
        XCTAssertEqual(response.user, network.updateProfileInfoResponse.user)
        XCTAssertNotNil(storage.loadUser())
        guard case .signedIn = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
    }

    func test_autoSignIn_whenTokenAndUserExist_emitsSignedIn() throws {
        // Given
        let user = UserModel.mock
        let storage = MockLocalStorage(user: user)
        let keychain = MockKeychain(token: Data("token".utf8))

        // When
        let sut = makeSUT(keychain: keychain, storage: storage)

        // Then
        guard case .signedIn(let restored) = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
        XCTAssertEqual(restored, user)
    }

    func test_autoSignIn_whenNoToken_emitsSignedOut() {
        // Given / When
        let sut = makeSUT(keychain: MockKeychain())

        // Then
        guard case .signedOut = sut.authState.value else {
            return XCTFail("Ожидался signedOut")
        }
    }
    
    func test_autoSignIn_updatesTheSavedProfileFromTheServer() async {
        // Given
        let keychain = MockKeychain()
        keychain.saveAuthToken("token")
        let storage = MockLocalStorage(user: .mock)
        let network = MockNetworkService()
        network.authTokenResponse = AuthTokenResponse(token: "token", user: renamedUser())

        // When
        let sut = makeSUT(keychain: keychain, network: network, storage: storage)
        await waitUntil { storage.loadUser()?.name == "Новое имя" }

        // Then
        guard case .signedIn(let user) = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
        XCTAssertEqual(user.name, "Новое имя")
    }

    func test_refreshUser_whenProfileUnchanged_emitsNothing() async throws {
        // Given
        let network = MockNetworkService()
        let sut = makeSUT(network: network)
        try await sut.signIn(email: "a@b.com", password: "123456")
        var events = 0
        let cancellable = sut.authState.dropFirst().sink { _ in events += 1 }

        // When
        sut.refreshUser()
        try await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertEqual(events, 0)
        cancellable.cancel()
    }

    // MARK: - Session expiry
    func test_sessionExpiry_ofTheCurrentToken_endsTheSession() async throws {
        // Given
        let network = MockNetworkService()
        let sut = makeSUT(network: network)
        try await sut.signIn(email: "a@b.com", password: "123456")

        // When
        network.sessionExpiredContinuation.yield(network.authTokenResponse.token)
        await waitUntil { if case .signedOut = sut.authState.value { true } else { false } }

        // Then
        guard case .signedOut = sut.authState.value else {
            return XCTFail("Ожидался signedOut")
        }
    }

    func test_sessionExpiry_ofThePreviousToken_keepsTheCurrentSession() async throws {
        // Given
        let keychain = MockKeychain()
        let network = MockNetworkService()
        let sut = makeSUT(keychain: keychain, network: network)
        try await sut.signIn(email: "a@b.com", password: "123456")

        // When
        network.sessionExpiredContinuation.yield("token-of-the-previous-account")
        try await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertNotNil(keychain.loadAuthToken())
        guard case .signedIn = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
    }

    func test_updateProfileInfo_afterSignOut_doesNotBringTheSessionBack() async throws {
        // Given
        let storage = MockLocalStorage()
        let sut = makeSUT(storage: storage)

        // When
        _ = try await sut.updateProfileInfo(ProfileInfoModel())

        // Then
        XCTAssertNil(storage.loadUser())
        guard case .signedOut = sut.authState.value else {
            return XCTFail("Ожидался signedOut")
        }
    }

    // MARK: - Keychain after a restart
    func test_restoreSession_whenTokenBecomesReadable_signsIn() throws {
        // Given: the Keychain gave nothing at launch
        let keychain = MockKeychain()
        let storage = MockLocalStorage(user: .mock)
        let sut = makeSUT(keychain: keychain, storage: storage)
        keychain.saveAuthToken("token")

        // When
        sut.restoreSessionIfNeeded()

        // Then
        guard case .signedIn(let user) = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
        XCTAssertEqual(user, UserModel.mock)
    }

    func test_restoreSession_afterSignOut_staysSignedOutAndEmitsNothing() async throws {
        // Given
        let sut = makeSUT()
        try await sut.signIn(email: "a@b.com", password: "123456")
        sut.signOut()
        var events = 0
        let cancellable = sut.authState.dropFirst().sink { _ in events += 1 }

        // When
        sut.restoreSessionIfNeeded()

        // Then
        XCTAssertEqual(events, 0)
        cancellable.cancel()
    }

    // MARK: - Helpers
    private func renamedUser() -> UserModel {
        let user = UserModel.mock

        return UserModel(id: user.id,
                         name: "Новое имя",
                         email: user.email,
                         dateOfBirth: user.dateOfBirth,
                         birthTime: user.birthTime,
                         gender: user.gender,
                         socialType: user.socialType,
                         conflictStyle: user.conflictStyle,
                         emotionalCore: user.emotionalCore,
                         decisionStyle: user.decisionStyle,
                         coreFocus: user.coreFocus,
                         hasAIConsent: user.hasAIConsent)
    }

    private func makeSUT(keychain: MockKeychain = MockKeychain(),
                         network: MockNetworkService? = nil,
                         storage: MockLocalStorage = MockLocalStorage()) -> AuthService {
        AuthService(networkService: network ?? MockNetworkService(), keychain: keychain, storage: storage)
    }
}
