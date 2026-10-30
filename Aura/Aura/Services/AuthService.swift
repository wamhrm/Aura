//
//  AuthService.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import Combine
import Foundation

enum AuthState {
    case signedIn(UserModel)
    case signedOut
}

protocol AuthServiceProtocol {
    var authState: CurrentValueSubject<AuthState, Never> { get }

    func createAccount(name: String, email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse
    func giveAIConsent() async throws
    func signOut()
    func deleteAccount() async throws
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    private(set) var authState = CurrentValueSubject<AuthState, Never>(.signedOut)

    private let networkService: any NetworkServiceProtocol
    private let keychain: any KeychainHelperProtocol
    private let storage: any LocalStorageProtocol

    init(networkService: any NetworkServiceProtocol = NetworkService(),
         keychain: any KeychainHelperProtocol = KeychainHelper(),
         storage: any LocalStorageProtocol = LocalStorage()) {
        self.networkService = networkService
        self.keychain = keychain
        self.storage = storage

        autoSignIn()
        observeSessionExpiration()
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let normalizedEmail = normalizeEmail(email)
        try await networkService.createAccount(name: name, email: normalizedEmail, password: password)
        try await signIn(email: normalizedEmail, password: password)
    }

    func signIn(email: String, password: String) async throws {
        let response = try await networkService.signIn(email: normalizeEmail(email), password: password)
        startSession(with: response)
    }

    func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) async throws {
        let response = try await networkService.signInWithApple(identityToken: identityToken,
                                                                authorizationCode: authorizationCode,
                                                                nonce: nonce,
                                                                name: name)
        startSession(with: response)
    }

    func requestPasswordReset(email: String) async throws {
        try await networkService.requestPasswordReset(email: normalizeEmail(email))
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let response = try await networkService.resetPassword(email: normalizeEmail(email),
                                                              code: code,
                                                              password: newPassword)
        startSession(with: response)
    }

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let response = try await networkService.updateProfileInfo(request)
        storage.saveUser(response.user)
        if let horoscope = response.horoscope {
            storage.save(horoscope, for: StorageKeys.horoscope, userId: response.user.id)
        }
        authState.send(.signedIn(response.user))
        return response
    }

    func giveAIConsent() async throws {
        let user = try await networkService.giveAIConsent()
        guard case .signedIn(let currentUser) = authState.value, currentUser.id == user.id else { return }

        storage.saveUser(user)
        authState.send(.signedIn(user))
    }

    func signOut() {
        if let token = keychain.loadAuthToken() {
            let networkService = networkService
            Task { try? await networkService.logout(token: token) }
        }

        endSession()
    }

    func deleteAccount() async throws {
        try await networkService.deleteAccount()
        endSession()
    }

    private func endSession() {
        if let user = storage.loadUser() {
            storage.deleteAll(for: user.id)
        }

        keychain.deleteAuthToken()
        storage.deleteUser()
        authState.send(.signedOut)
    }

    private func observeSessionExpiration() {
        let events = networkService.sessionExpiredEvents

        Task { [weak self] in
            for await _ in events {
                guard let self, case .signedIn = authState.value else { continue }
                endSession()
            }
        }
    }

    private func autoSignIn() {
        let hasToken = keychain.loadAuthToken() != nil

        if hasToken, let user = storage.loadUser() {
            authState.send(.signedIn(user))
            return
        }

        if hasToken {
            keychain.deleteAuthToken()
        }

        authState.send(.signedOut)
    }

    private func startSession(with response: AuthTokenResponse) {
        keychain.saveAuthToken(response.token)
        storage.saveUser(response.user)
        authState.send(.signedIn(response.user))
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
