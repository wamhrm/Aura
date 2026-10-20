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

    func test_createAccount_callsNetworkThenSignsIn() async throws {
        // Given
        let network = MockNetworkService()
        let sut = makeSUT(network: network)

        // When
        try await sut.createAccount(name: "Имя", email: "a@b.com", password: "123456")

        // Then
        XCTAssertEqual(network.createAccountCallCount, 1)
        XCTAssertEqual(network.signInCallCount, 1)
        guard case .signedIn = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
    }

    func test_updateProfileInfo_savesUserEmitsSignedInAndReturnsResponse() async throws {
        // Given
        let network = MockNetworkService()
        let storage = MockLocalStorage()
        let sut = makeSUT(network: network, storage: storage)

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
    
    // MARK: - Helpers
    private func makeSUT(keychain: MockKeychain = MockKeychain(),
                         network: MockNetworkService? = nil,
                         storage: MockLocalStorage = MockLocalStorage()) -> AuthService {
        AuthService(networkService: network ?? MockNetworkService(), keychain: keychain, storage: storage)
    }
}
