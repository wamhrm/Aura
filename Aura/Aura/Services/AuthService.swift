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
    func sendEmailConfirmationCode() async throws
    func confirmEmail(code: String) async throws
    func signOut() throws
    func deleteAccount() async throws
    func refreshUser()
    func restoreSessionIfNeeded() async
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    private(set) var authState = CurrentValueSubject<AuthState, Never>(.signedOut)

    private let networkService: any NetworkServiceProtocol
    private let keychain: any KeychainHelperProtocol
    private let storage: LocalStorage
    private var refreshTask: Task<Void, Never>?

    private var currentUser: UserModel? {
        if case .signedIn(let user) = authState.value { return user }
        return nil
    }

    init(networkService: any NetworkServiceProtocol,
         keychain: any KeychainHelperProtocol = KeychainHelper(),
         storage: LocalStorage = LocalStorage()) {
        self.networkService = networkService
        self.keychain = keychain
        self.storage = storage

        autoSignIn()
        observeSessionExpiration()
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let response = try await networkService.createAccount(name: name, email: normalizeEmail(email), password: password)
        try startSession(response: response)
    }

    func signIn(email: String, password: String) async throws {
        let response = try await networkService.signIn(email: normalizeEmail(email), password: password)
        try startSession(response: response)
    }

    func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) async throws {
        let response = try await networkService.signInWithApple(identityToken: identityToken,
                                                                authorizationCode: authorizationCode,
                                                                nonce: nonce,
                                                                name: name)
        try startSession(response: response)
    }

    func requestPasswordReset(email: String) async throws {
        try await networkService.requestPasswordReset(email: normalizeEmail(email))
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let response = try await networkService.resetPassword(email: normalizeEmail(email),
                                                              code: code,
                                                              password: newPassword)
        try startSession(response: response)
    }

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        cancelRefresh()
        let token = try keychain.loadAuthToken()
        let response = try await networkService.updateProfileInfo(request)

        guard let currentUser, currentUser.id == response.user.id,
              try keychain.loadAuthToken() == token else { return response }

        cancelRefresh()
        var user = response.user
        // Consent and confirmation may have completed while the profile was being saved.
        if currentUser.hasAIConsent == true { user.hasAIConsent = true }
        if currentUser.isEmailConfirmed == true { user.isEmailConfirmed = true }
        storage.saveUser(user: user)
        authState.send(.signedIn(user))
        return UpdateProfileInfoResponse(user: user, horoscope: response.horoscope)
    }

    func giveAIConsent() async throws {
        cancelRefresh()
        let token = try keychain.loadAuthToken()
        let response = try await networkService.giveAIConsent()
        guard var user = currentUser, user.id == response.id,
              try keychain.loadAuthToken() == token else { return }

        cancelRefresh()
        // This endpoint changes consent, not the rest of the current profile.
        user.hasAIConsent = response.hasAIConsent
        storage.saveUser(user: user)
        authState.send(.signedIn(user))
    }

    func sendEmailConfirmationCode() async throws {
        try await networkService.sendEmailConfirmationCode()
    }

    func confirmEmail(code: String) async throws {
        cancelRefresh()
        let token = try keychain.loadAuthToken()
        let response = try await networkService.confirmEmail(code: code)
        guard var user = currentUser, user.id == response.id,
              try keychain.loadAuthToken() == token else { return }

        cancelRefresh()
        user.isEmailConfirmed = response.isEmailConfirmed
        storage.saveUser(user: user)
        authState.send(.signedIn(user))
    }

    func signOut() throws {
        let token = try? keychain.loadAuthToken()
        try endSession()

        if let token {
            let networkService = networkService
            Task { try? await networkService.logout(token: token) }
        }
    }

    func deleteAccount() async throws {
        try await networkService.deleteAccount()
        try endSession()
    }

    private func endSession() throws {
        try keychain.deleteAuthToken()
        cancelRefresh()
        if let user = storage.loadUser() {
            storage.deleteAll(userId: user.id)
        }

        storage.deleteUser()
        authState.send(.signedOut)
    }

    private func observeSessionExpiration() {
        let events = networkService.sessionExpiredEvents

        Task { [weak self] in
            for await expiredToken in events {
                // A late answer to a request of the previous session must not end the current one
                guard let self, expiredToken == (try? keychain.loadAuthToken()) else { continue }
                try? endSession()
            }
        }
    }

    private func autoSignIn() {
        guard (try? keychain.loadAuthToken()) != nil, let user = storage.loadUser() else { return }
        authState.send(.signedIn(user))
        refreshUser()
    }

    func restoreSessionIfNeeded() async {
        guard currentUser == nil, (try? keychain.loadAuthToken()) != nil else { return }
        if let user = storage.loadUser() {
            authState.send(.signedIn(user))
            refreshUser()
            return
        }
        refreshUser()
        await refreshTask?.value
    }

    func refreshUser() {
        guard refreshTask == nil, let token = try? keychain.loadAuthToken() else { return }
        let previousUser = currentUser
        let networkService = networkService

        refreshTask = Task { [weak self] in
            let user = try? await networkService.fetchCurrentUser()
            guard let self, !Task.isCancelled else { return }
            defer { refreshTask = nil }

            guard let user, currentUser == previousUser, user != currentUser,
                  (try? keychain.loadAuthToken()) == token else { return }

            storage.saveUser(user: user)
            authState.send(.signedIn(user))
        }
    }

    private func cancelRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func startSession(response: AuthTokenResponse) throws {
        try keychain.saveAuthToken(response.token)
        cancelRefresh()
        storage.saveUser(user: response.user)
        authState.send(.signedIn(response.user))
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension AuthService {
    static let preview = AuthService(networkService: NetworkService())
}
