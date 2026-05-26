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
    var authState = CurrentValueSubject<AuthState, Never>(.signedOut)

    private let tokenPath = Constants.tokenPath
    private let tokenKey = Constants.tokenKey
    private let userKey = Constants.userKey

    init() {
        autoSignIn()
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let normalizedEmail = normalizeEmail(email)
        try await NetworkService.createAccount(name: name, email: normalizedEmail, password: password)
        try await signIn(email: normalizedEmail, password: password)
    }

    func signIn(email: String, password: String) async throws {
        let response = try await NetworkService.signIn(email: normalizeEmail(email), password: password)

        saveToken(response.token)
        saveUserLocally(response.user)
        authState.send(.signedIn(response.user))
    }

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let response = try await NetworkService.updateProfileInfo(request)
        saveUserLocally(response.user)
        authState.send(.signedIn(response.user))
        return response
    }

    func signOut() {
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            UserDefaultsHelper.deleteLocalHoroscope(for: user.id)
            UserDefaultsHelper.deleteLocalPersonality(for: user.id)
            UserDefaultsHelper.deleteLocalDailyInsight(for: user.id)
            UserDefaultsHelper.deleteLocalDailyTip(for: user.id)
        }

        KeychainHelper.standard.deleteToken(path: tokenPath, key: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        authState.send(.signedOut)
    }

    private func autoSignIn() {
        if let _ = KeychainHelper.standard.getToken(path: tokenPath, key: tokenKey),
           let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            authState.send(.signedIn(user))
        } else {
            authState.send(.signedOut)
        }
    }

    private func saveUserLocally(_ user: UserModel) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private func saveToken(_ token: String) {
        if let data = token.data(using: .utf8) {
            KeychainHelper.standard.saveToken(data, path: tokenPath, key: tokenKey)
        }
    }

    private func normalizeEmail(_ email: String) -> String {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
