//
//  MockAuthService.swift
//  AuraUnitTests
//

import Combine
import Foundation
@testable import Aura

enum MockError: Error {
    case notStubbed
}

@MainActor
final class MockAuthService: AuthServiceProtocol {
    let authState: CurrentValueSubject<AuthState, Never>

    var updateProfileInfoResult: UpdateProfileInfoResponse?
    var errorToThrow: Error?

    private(set) var signInCallCount = 0
    private(set) var createAccountCallCount = 0
    private(set) var signOutCallCount = 0

    init(state: AuthState = .signedOut) {
        authState = CurrentValueSubject<AuthState, Never>(state)
    }

    func createAccount(name: String, email: String, password: String) async throws {
        createAccountCallCount += 1
        if let errorToThrow { throw errorToThrow }
    }

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        if let errorToThrow { throw errorToThrow }
    }

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        if let errorToThrow { throw errorToThrow }
        guard let updateProfileInfoResult else { throw MockError.notStubbed }
        return updateProfileInfoResult
    }

    func signOut() {
        signOutCallCount += 1
        authState.send(.signedOut)
    }
}
