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

    func noteAIConsentAsked()
    func finishOnboarding()
    func createAccount(name: String, email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithApple(identityToken: String, authorizationCode: String?, nonce: String, name: String?) async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse
    func giveAIConsent() async throws
    func sendEmailConfirmationCode() async throws
    func confirmEmail(code: String) async throws
    func signOut() async throws
    func deleteAccount() async throws
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    private(set) var authState = CurrentValueSubject<AuthState, Never>(.signedOut)
    @Published private(set) var showsMainScreen = false
    private(set) var didAskAIConsent = false

    private let networkService: any NetworkServiceProtocol
    private let keychain: any KeychainHelperProtocol
    private let storage: LocalStorage

    init(networkService: any NetworkServiceProtocol,
         keychain: any KeychainHelperProtocol = KeychainHelper(),
         storage: LocalStorage = LocalStorage()) {
        self.networkService = networkService
        self.keychain = keychain
        self.storage = storage

        autoSignIn()
    }

    func noteAIConsentAsked() {
        didAskAIConsent = true
    }

    func finishOnboarding() {
        openMainIfProfileIsComplete()
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let response = try await networkService.createAccount(name: name,
                                                              email: normalizeEmail(email),
                                                              password: password)
        try startSession(response: response)
    }

    func signIn(email: String, password: String) async throws {
        let response = try await networkService.signIn(email: normalizeEmail(email),
                                                       password: password)
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
        let response = try await networkService.updateProfileInfo(request)
        saveUser(response.user)
        return response
    }

    func giveAIConsent() async throws {
        let user = try await networkService.giveAIConsent()
        saveUser(user)
    }

    func sendEmailConfirmationCode() async throws {
        try await networkService.sendEmailConfirmationCode()
    }

    func confirmEmail(code: String) async throws {
        let user = try await networkService.confirmEmail(code: code)
        saveUser(user)
    }

    func signOut() async throws {
        try? await networkService.logout()
        try endSession()
    }

    func deleteAccount() async throws {
        try await networkService.deleteAccount()
        try endSession()
    }

    private func endSession() throws {
        try keychain.deleteAuthToken()
        if let user = storage.loadUser() {
            storage.deleteAll(userId: user.id)
        }

        storage.deleteUser()
        showsMainScreen = false
        didAskAIConsent = false
        authState.send(.signedOut)
    }

    private func autoSignIn() {
        guard (try? keychain.loadAuthToken()) != nil, let user = storage.loadUser() else { return }
        authState.send(.signedIn(user))
        openMainIfProfileIsComplete()
    }

    private func startSession(response: AuthTokenResponse) throws {
        try keychain.saveAuthToken(response.token)
        saveUser(response.user)
    }

    private func saveUser(_ user: UserModel) {
        storage.saveUser(user: user)
        authState.send(.signedIn(user))
    }

    private func openMainIfProfileIsComplete() {
        guard case .signedIn(let user) = authState.value, user.hasCompletedProfileInfo else { return }
        showsMainScreen = true
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension AuthService {
    static let preview = AuthService(networkService: NetworkService())
}
