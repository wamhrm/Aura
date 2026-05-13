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

@MainActor
protocol AuthServiceProtocol: AnyObject {
    var authState: AuthState { get }
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }

    func createAccount(name: String, email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func updateProfileInfo(_ request: UpdateProfileInfoRequest) async throws -> UserModel
    func restoreSession() async
    func signOut()
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    @Published private(set) var authState: AuthState = .signedOut

    private let tokenStorage: TokenStorageProtocol

    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }

    init(tokenStorage: (any TokenStorageProtocol)? = nil) {
        self.tokenStorage = tokenStorage ?? KeychainTokenStorage()

        Task {
            await restoreSession()
        }
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let body = AuthRequest(name: name, email: email, password: password)
        let response: AuthResponse = try await NetworkHelper.request(endpoint: "/auth/createAccount",
                                                                     method: .post,
                                                                     body: body)
        
        try saveToken(response.token)
        authState = .signedIn(response.user)
    }

    func signIn(email: String, password: String) async throws {
        let body = AuthRequest(email: email, password: password)
        let response: AuthResponse = try await NetworkHelper.request(endpoint: "/auth/signIn",
                                                                     method: .post,
                                                                     body: body)
        
        try saveToken(response.token)
        authState = .signedIn(response.user)
    }

    func updateProfileInfo(_ request: UpdateProfileInfoRequest) async throws -> UserModel {
        guard let token = try tokenStorage.readToken() else {
            throw AuthError.missingToken
        }

        let user: UserModel = try await NetworkHelper.request(endpoint: "/auth/profileInfo",
                                                              method: .patch,
                                                              body: request,
                                                              token: token)
        authState = .signedIn(user)

        return user
    }

    func restoreSession() async {
        do {
            guard let token = try tokenStorage.readToken() else {
                authState = .signedOut
                return
            }

            let user: UserModel = try await NetworkHelper.request(endpoint: "/auth/autoSignIn",
                                                                  method: .get,
                                                                  token: token)
            
            authState = .signedIn(user)
        } catch {
            if case NetworkError.unauthorized = error {
                try? tokenStorage.deleteToken()
            }

            authState = .signedOut
        }
    }

    func signOut() {
        try? tokenStorage.deleteToken()
        authState = .signedOut
    }

    private func saveToken(_ token: String) throws {
        try tokenStorage.saveToken(token)

        guard try tokenStorage.readToken() != nil else {
            throw KeychainError.invalidData
        }
    }
}

private struct AuthRequest: Encodable {
    let name: String?
    let email: String
    let password: String

    init(name: String? = nil, email: String, password: String) {
        self.name = name
        self.email = email
        self.password = password
    }
}

private struct AuthResponse: Decodable {
    let token: String
    let user: UserModel
}

enum AuthError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        switch self {
            case .missingToken:
                return "Войдите в аккаунт, чтобы сохранить профиль"
        }
    }
}
