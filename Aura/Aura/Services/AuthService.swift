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
    var sessionID: UUID? { get }

    func finishOnboarding()
    func createAccount(name: String, email: String, password: String) async throws
    func ensureEmailAvailable(email: String) async throws
    func signIn(email: String, password: String) async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse
    func giveAIConsent() async throws
    func sendEmailConfirmationCode() async throws
    func confirmEmail(code: String) async throws
    func signOut() async throws
    func deleteAccount() async throws
    func endExpiredSession()
    func takeExpiredSessionMessage() -> String?
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    private(set) var authState = CurrentValueSubject<AuthState, Never>(.signedOut)
    @Published private(set) var showsMainScreen = false
    private(set) var sessionID: UUID?

    private let networkService: any NetworkServiceProtocol
    private let keychain: any KeychainHelperProtocol
    private let userDefaults: UserDefaults
    private var expiredSessionMessage: String?

    init(networkService: any NetworkServiceProtocol,
         keychain: any KeychainHelperProtocol = KeychainHelper(),
         userDefaults: UserDefaults = Constants.userDefaults) {
        self.networkService = networkService
        self.keychain = keychain
        self.userDefaults = userDefaults

        autoSignIn()
    }

    func finishOnboarding() {
        openMainIfProfileIsComplete()
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let response = try await request {
            try await networkService.createAccount(name: name,
                                                   email: normalizeEmail(email),
                                                   password: password)
        }
        try startSession(response: response)
    }

    func ensureEmailAvailable(email: String) async throws {
        try await request {
            try await networkService.ensureEmailAvailable(email: normalizeEmail(email))
        }
    }

    func signIn(email: String, password: String) async throws {
        let response = try await request {
            try await networkService.signIn(email: normalizeEmail(email),
                                            password: password)
        }
        try startSession(response: response)
    }

    func requestPasswordReset(email: String) async throws {
        try await request {
            try await networkService.requestPasswordReset(email: normalizeEmail(email))
        }
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let response = try await request {
            try await networkService.resetPassword(email: normalizeEmail(email),
                                                   code: code,
                                                   password: newPassword)
        }
        try startSession(response: response)
    }

    func updateProfileInfo(_ request: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let response = try await self.request {
            try await networkService.updateProfileInfo(request)
        }
        guard case .signedIn(let user) = authState.value, user.id == response.user.id else {
            throw NetworkError.sessionExpired
        }
        saveUser(response.user)
        return response
    }

    func giveAIConsent() async throws {
        let user = try await request {
            try await networkService.giveAIConsent()
        }
        guard case .signedIn(let currentUser) = authState.value, currentUser.id == user.id else {
            throw NetworkError.sessionExpired
        }
        saveUser(user)
    }

    func sendEmailConfirmationCode() async throws {
        try await request {
            try await networkService.sendEmailConfirmationCode()
        }
    }

    func confirmEmail(code: String) async throws {
        let user = try await request {
            try await networkService.confirmEmail(code: code)
        }
        guard case .signedIn(let currentUser) = authState.value, currentUser.id == user.id else {
            throw NetworkError.sessionExpired
        }
        saveUser(user)
    }

    func signOut() async throws {
        let sessionID = sessionID
        try? await networkService.logout()
        guard sessionID == self.sessionID else { throw NetworkError.cancelled }
        try endSession()
    }

    func deleteAccount() async throws {
        try await request {
            try await networkService.deleteAccount()
        }
        try endSession()
    }

    func endExpiredSession() {
        do {
            try endSession()
            expiredSessionMessage = NetworkError.sessionExpired.errorDescription
        } catch {
            expiredSessionMessage = nil
        }
    }

    func takeExpiredSessionMessage() -> String? {
        let message = expiredSessionMessage
        expiredSessionMessage = nil
        return message
    }

    private func request<T>(_ operation: () async throws -> T) async throws -> T {
        let sessionID = sessionID

        do {
            let result = try await operation()
            guard sessionID == self.sessionID else { throw NetworkError.cancelled }
            return result
        } catch NetworkError.sessionExpired {
            guard sessionID == self.sessionID else { throw NetworkError.cancelled }
            endExpiredSession()
            throw NetworkError.sessionExpired
        }
    }

    private func endSession() throws {
        try keychain.deleteAuthToken()
        userDefaults.removeObject(forKey: Constants.userKey)
        sessionID = nil
        showsMainScreen = false
        authState.send(.signedOut)
    }

    private func autoSignIn() {
        guard (try? keychain.loadAuthToken()) != nil, let user = loadUser() else { return }
        sessionID = UUID()
        authState.send(.signedIn(user))
        openMainIfProfileIsComplete()
    }

    private func startSession(response: AuthTokenResponse) throws {
        try keychain.saveAuthToken(response.token)
        sessionID = UUID()
        saveUser(response.user)
    }

    private func saveUser(_ user: UserModel) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: Constants.userKey)
        }
        authState.send(.signedIn(user))
    }

    private func loadUser() -> UserModel? {
        guard let data = userDefaults.data(forKey: Constants.userKey) else { return nil }
        return try? JSONDecoder().decode(UserModel.self, from: data)
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
