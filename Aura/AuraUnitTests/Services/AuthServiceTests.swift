//
//  AuthServiceTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class AuthServiceTests: XCTestCase {
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

    // MARK: - Helpers
    private func makeSUT(keychain: MockKeychain = MockKeychain(),
                         network: MockNetworkService? = nil,
                         storage: MockLocalStorage = MockLocalStorage()) -> AuthService {
        AuthService(networkService: network ?? MockNetworkService(), keychain: keychain, storage: storage)
    }
}
