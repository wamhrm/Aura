//
//  AuthService.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
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
    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse
    func signOut()
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    private(set) var authState = CurrentValueSubject<AuthState, Never>(.signedOut)

    private let tokenPath = Constants.tokenPath
    private let tokenKey = Constants.tokenKey

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
        saveToken(response.token)
        saveUserLocally(response.user)
        authState.send(.signedIn(response.user))
    }

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let response = try await networkService.updateProfileInfo(request)
        saveUserLocally(response.user)
        authState.send(.signedIn(response.user))
        return response
    }

    func signOut() {
        if let tokenData = keychain.getToken(path: tokenPath, key: tokenKey),
           let token = String(data: tokenData, encoding: .utf8) {
            let networkService = networkService
            Task { try? await networkService.logout(token: token) }
        }

        endSession()
    }

    private func endSession() {
        if let user = storage.loadUser() {
            storage.deleteAll(for: user.id)
        }

        keychain.deleteToken(path: tokenPath, key: tokenKey)
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
        let hasToken = keychain.getToken(path: tokenPath, key: tokenKey) != nil

        if hasToken, let user = storage.loadUser() {
            authState.send(.signedIn(user))
            return
        }

        if hasToken {
            keychain.deleteToken(path: tokenPath, key: tokenKey)
        }

        authState.send(.signedOut)
    }

    private func saveUserLocally(_ user: UserModel) {
        storage.saveUser(user)
    }

    private func saveToken(_ token: String) {
        if let data = token.data(using: .utf8) {
            keychain.saveToken(data, path: tokenPath, key: tokenKey)
        }
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
