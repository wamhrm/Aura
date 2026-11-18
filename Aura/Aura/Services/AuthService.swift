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
    @Published private(set) var restorationState = LoadState.loading
    private(set) var sessionID: UUID?

    private let networkService: any NetworkServiceProtocol
    private let keychain: any KeychainHelperProtocol
    private var expiredSessionMessage: String?

    init(networkService: any NetworkServiceProtocol,
         keychain: any KeychainHelperProtocol = KeychainHelper(),
         userDefaults: UserDefaults = Constants.userDefaults) {
        self.networkService = networkService
        self.keychain = keychain
        userDefaults.removeObject(forKey: Constants.userKey)
    }

    func restoreSession() async {
        guard restorationState != .loaded else { return }
        var sessionID = sessionID

        do {
            guard try keychain.loadAuthToken() != nil else {
                restorationState = .loaded
                return
            }

            sessionID = UUID()
            self.sessionID = sessionID
            let user = try await networkService.fetchCurrentUser()
            guard sessionID == self.sessionID else { return }
            authState.send(.signedIn(user))
            openMainIfProfileIsComplete()
            restorationState = .loaded
        } catch NetworkError.sessionExpired {
            guard sessionID == self.sessionID else { return }
            endExpiredSession()
        } catch {
            guard sessionID == self.sessionID else { return }
            restorationState = .failed(error.userMessage)
        }
    }

    func retryRestoreSession() {
        guard case .failed = restorationState else { return }
        restorationState = .loading
        Task { await restoreSession() }
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
        authState.send(.signedIn(response.user))
        return response
    }

    func giveAIConsent() async throws {
        let user = try await request {
            try await networkService.giveAIConsent()
        }
        guard case .signedIn(let currentUser) = authState.value, currentUser.id == user.id else {
            throw NetworkError.sessionExpired
        }
        authState.send(.signedIn(user))
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
        authState.send(.signedIn(user))
    }

    func signOut() async throws {
        let sessionID = sessionID
        try? await networkService.logout()
        guard sessionID == self.sessionID else { throw NetworkError.cancelled }
        try keychain.deleteAuthToken()
        clearSession()
    }

    func deleteAccount() async throws {
        try await request {
            try await networkService.deleteAccount()
        }
        clearInvalidSession()
    }

    func endExpiredSession() {
        expiredSessionMessage = NetworkError.sessionExpired.errorDescription
        clearInvalidSession()
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

    private func clearInvalidSession() {
        clearSession()
        try? keychain.deleteAuthToken()
    }

    private func clearSession() {
        sessionID = nil
        showsMainScreen = false
        authState.send(.signedOut)
        restorationState = .loaded
    }

    private func startSession(response: AuthTokenResponse) throws {
        try keychain.saveAuthToken(response.token)
        sessionID = UUID()
        authState.send(.signedIn(response.user))
        restorationState = .loaded
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
