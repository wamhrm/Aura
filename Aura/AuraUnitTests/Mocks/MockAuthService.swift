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

    init(state: AuthState = .signedOut) {
        authState = CurrentValueSubject<AuthState, Never>(state)
    }

    func createAccount(name: String, email: String, password: String) async throws {}

    func signIn(email: String, password: String) async throws {}

    func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) async throws {}

    func requestPasswordReset(email: String) async throws {}

    func resetPassword(email: String, code: String, newPassword: String) async throws {}

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        UpdateProfileInfoResponse(user: .mock, horoscope: .mock)
    }

    func giveAIConsent() async throws {}

    func sendEmailConfirmationCode() async throws {}

    func confirmEmail(code: String) async throws {}

    func signOut() {}

    func deleteAccount() async throws {}

    func refreshUser() {}

    func restoreSessionIfNeeded() {}
}
