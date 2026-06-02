//
//  AuthServiceTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class AuthServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: Constants.userKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: Constants.userKey)
        super.tearDown()
    }

    func test_signIn_savesTokenAndUserAndEmitsSignedIn() async throws {
        // Given
        let keychain = MockKeychain()
        let network = MockNetworkService()
        let sut = makeSUT(keychain: keychain, network: network)

        // When
        try await sut.signIn(email: "a@b.com", password: "123456")

        // Then
        XCTAssertNotNil(keychain.getToken(path: "", key: ""))
        XCTAssertNotNil(UserDefaults.standard.data(forKey: Constants.userKey))
        guard case .signedIn(let user) = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
        XCTAssertEqual(user, network.authTokenResponse.user)
    }

    func test_signOut_clearsTokenAndUserAndEmitsSignedOut() async throws {
        // Given
        let keychain = MockKeychain()
        let sut = makeSUT(keychain: keychain)
        try await sut.signIn(email: "a@b.com", password: "123456")

        // When
        sut.signOut()

        // Then
        XCTAssertNil(keychain.getToken(path: "", key: ""))
        XCTAssertNil(UserDefaults.standard.data(forKey: Constants.userKey))
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
        let sut = makeSUT(network: network)

        // When
        let response = try await sut.updateProfileInfo(ProfileInfoModel())

        // Then
        XCTAssertEqual(response.user, network.updateProfileInfoResponse.user)
        XCTAssertNotNil(UserDefaults.standard.data(forKey: Constants.userKey))
        guard case .signedIn = sut.authState.value else {
            return XCTFail("Ожидался signedIn")
        }
    }

    func test_autoSignIn_whenTokenAndUserExist_emitsSignedIn() throws {
        // Given
        let user = UserModel.mock
        UserDefaults.standard.set(try JSONEncoder().encode(user), forKey: Constants.userKey)
        let keychain = MockKeychain(token: Data("token".utf8))

        // When
        let sut = makeSUT(keychain: keychain)

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
                         network: MockNetworkService? = nil) -> AuthService {
        AuthService(networkService: network ?? MockNetworkService(), keychain: keychain)
    }
}
