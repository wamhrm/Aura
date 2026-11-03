//
//  NetworkService.swift
//  Aura
//
//  Created by wamhrm on 13.05.2026.
//

import Foundation
import os

fileprivate enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

fileprivate enum RequestAuthorization {
    case none, storedToken
    case token(String)
}

protocol NetworkServiceProtocol: Sendable {
    var sessionExpiredEvents: AsyncStream<String> { get }

    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse
    func signIn(email: String, password: String) async throws -> AuthTokenResponse
    func signInWithApple(identityToken: String,
                         authorizationCode: String?,
                         nonce: String,
                         name: String?) async throws -> AuthTokenResponse
    func logout(token: String) async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse
    func deleteAccount() async throws
    func fetchCurrentUser() async throws -> UserModel
    func giveAIConsent() async throws -> UserModel
    func sendEmailConfirmationCode() async throws
    func confirmEmail(code: String) async throws -> UserModel
    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse
    func fetchCurrentHoroscope() async throws -> HoroscopeModel
    func fetchDailyInsight() async throws -> DailyContentModel
    func fetchDailyTip() async throws -> DailyContentModel
    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel
    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel
    func fetchHistory() async throws -> [HistoryCellModel]
    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel
    func deleteHistory(id: UUID) async throws
}

nonisolated final class NetworkService: NetworkServiceProtocol {
    private static let logger = Logger(subsystem: "ddorsat.Aura", category: "Network")
    private static let defaultTimeout: TimeInterval = 20
    // The server may wait for OpenAI up to 121 seconds
    private static let aiTimeout: TimeInterval = 130

    let sessionExpiredEvents: AsyncStream<String>

    private let baseURL: String
    private let session: URLSession
    private let sessionExpiredContinuation: AsyncStream<String>.Continuation

    private let keychain: any KeychainHelperProtocol

    init(baseURL: String = Constants.baseURL,
         session: URLSession = NetworkService.makeSession(),
         keychain: any KeychainHelperProtocol = KeychainHelper()) {
        self.baseURL = baseURL
        self.session = session
        self.keychain = keychain
        (sessionExpiredEvents, sessionExpiredContinuation) = AsyncStream.makeStream(of: String.self)
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 300
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse {
        let bodyData = try JSONEncoder().encode(AuthSignUpBody(name: name, email: email, password: password))
        let data = try await request(endpoint: "/auth/createAccount", method: .post, body: bodyData, authorization: .none)
        return try decode(AuthTokenResponse.self, from: data)
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        let bodyData = try JSONEncoder().encode(AuthSignInBody(email: email, password: password))
        let data = try await request(endpoint: "/auth/signIn", method: .post, body: bodyData, authorization: .none)
        return try decode(AuthTokenResponse.self, from: data)
    }

    func signInWithApple(identityToken: String,
                         authorizationCode: String?,
                         nonce: String,
                         name: String?) async throws -> AuthTokenResponse {
        let bodyData = try JSONEncoder().encode(AppleSignInBody(identityToken: identityToken,
                                                                authorizationCode: authorizationCode,
                                                                nonce: nonce,
                                                                name: name))
        let data = try await request(endpoint: "/auth/apple", method: .post, body: bodyData, authorization: .none)
        return try decode(AuthTokenResponse.self, from: data)
    }

    func logout(token: String) async throws {
        _ = try await request(endpoint: "/auth/logout", method: .post, authorization: .token(token))
    }

    func requestPasswordReset(email: String) async throws {
        let bodyData = try JSONEncoder().encode(PasswordResetRequestBody(email: email))
        _ = try await request(endpoint: "/auth/password/forgot", method: .post, body: bodyData, authorization: .none)
    }

    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse {
        let bodyData = try JSONEncoder().encode(PasswordResetBody(email: email, code: code, password: password))
        let data = try await request(endpoint: "/auth/password/reset", method: .post, body: bodyData, authorization: .none)
        return try decode(AuthTokenResponse.self, from: data)
    }

    func deleteAccount() async throws {
        _ = try await request(endpoint: "/auth/account", method: .delete)
    }

    func fetchCurrentUser() async throws -> UserModel {
        let data = try await request(endpoint: "/auth/me", method: .get)
        return try decode(UserModel.self, from: data)
    }

    func giveAIConsent() async throws -> UserModel {
        let data = try await request(endpoint: "/auth/aiConsent", method: .post)
        return try decode(UserModel.self, from: data)
    }

    func sendEmailConfirmationCode() async throws {
        _ = try await request(endpoint: "/auth/email/sendCode", method: .post)
    }

    func confirmEmail(code: String) async throws -> UserModel {
        let bodyData = try JSONEncoder().encode(EmailConfirmationBody(code: code))
        let data = try await request(endpoint: "/auth/email/confirm", method: .post, body: bodyData)
        return try decode(UserModel.self, from: data)
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let bodyData = try JSONEncoder().encode(profileInfo)
        let data = try await request(endpoint: "/auth/profileInfo", method: .patch, body: bodyData)
        return try decode(UpdateProfileInfoResponse.self, from: data)
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        let data = try await request(endpoint: "/horoscope/current", method: .get, timeout: Self.aiTimeout)
        return try decode(HoroscopeModel.self, from: data)
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/insight", method: .get, timeout: Self.aiTimeout)
        return try decode(DailyContentModel.self, from: data)
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/tip", method: .get, timeout: Self.aiTimeout)
        return try decode(DailyContentModel.self, from: data)
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel {
        let bodyData = try JSONEncoder().encode(selectedTests)
        let data = try await request(endpoint: "/history/personality",
                                     method: .post,
                                     body: bodyData,
                                     idempotencyKey: requestID,
                                     timeout: Self.aiTimeout)
        return try decode(PersonalityResultModel.self, from: data)
    }

    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel {
        let bodyData = try JSONEncoder().encode(testRequest)
        let data = try await request(endpoint: "/history/compatibility",
                                     method: .post,
                                     body: bodyData,
                                     idempotencyKey: requestID,
                                     timeout: Self.aiTimeout)
        return try decode(CompatibilityResultModel.self, from: data)
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        let data = try await request(endpoint: "/history", method: .get)
        return try decode([HistoryCellModel].self, from: data)
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        let data = try await request(endpoint: "/history/\(id.uuidString)", method: .get)
        return try decode(HistoryCellModel.self, from: data)
    }

    func deleteHistory(id: UUID) async throws {
        _ = try await request(endpoint: "/history/\(id.uuidString)", method: .delete)
    }

    private func request(endpoint: String,
                         method: HTTPMethod,
                         body: Data? = nil,
                         authorization: RequestAuthorization = .storedToken,
                         idempotencyKey: UUID? = nil,
                         timeout: TimeInterval = NetworkService.defaultTimeout,
                         attempt: Int = 0) async throws -> Data {
        do {
            return try await performRequest(endpoint: endpoint,
                                            method: method,
                                            body: body,
                                            authorization: authorization,
                                            idempotencyKey: idempotencyKey,
                                            timeout: timeout)
        } catch let urlError as URLError where method == .get && Self.isRetryable(urlError, timeout: timeout) && attempt < 2 {
            try await Task.sleep(for: Self.retryDelay(for: attempt))
            return try await request(endpoint: endpoint,
                                     method: method,
                                     body: body,
                                     authorization: authorization,
                                     idempotencyKey: idempotencyKey,
                                     timeout: timeout,
                                     attempt: attempt + 1)
        } catch let urlError as URLError {
            throw NetworkError(urlError: urlError)
        }
    }

    private func performRequest(endpoint: String,
                                method: HTTPMethod,
                                body: Data?,
                                authorization: RequestAuthorization,
                                idempotencyKey: UUID?,
                                timeout: TimeInterval) async throws -> Data {
        guard let baseURL = URL(string: baseURL),
              let url = URL(string: Constants.apiPath + endpoint, relativeTo: baseURL)?.absoluteURL else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(Constants.appVersion, forHTTPHeaderField: "X-App-Version")
        urlRequest.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Time-Zone")
        urlRequest.httpBody = body

        if let idempotencyKey {
            urlRequest.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "Idempotency-Key")
        }

        let token = bearerToken(for: authorization)
        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                guard let token else {
                    throw NetworkError(statusCode: httpResponse.statusCode, data: data)
                }

                sessionExpiredContinuation.yield(token)
                throw NetworkError.sessionExpired
            default:
                if httpResponse.statusCode >= 500 {
                    Self.logger.error("\(method.rawValue, privacy: .public) \(endpoint, privacy: .public) failed with status \(httpResponse.statusCode)")
                }

                throw NetworkError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private func bearerToken(for authorization: RequestAuthorization) -> String? {
        switch authorization {
            case .none:
                return nil
            case .token(let token):
                return token
            case .storedToken:
                return keychain.loadAuthToken()
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            Self.logger.error("Failed to decode \(String(describing: type), privacy: .public): \(String(describing: error), privacy: .public)")
            throw NetworkError.decodingError
        }
    }

    private static func isRetryable(_ error: URLError, timeout: TimeInterval) -> Bool {
        switch error.code {
            case .timedOut:
                // Repeating a long AI wait would keep the screen busy for minutes
                return timeout == defaultTimeout
            case .networkConnectionLost,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .notConnectedToInternet:
                return true
            default:
                return false
        }
    }

    private static func retryDelay(for attempt: Int) -> Duration {
        .seconds(Double(attempt) + 0.5)
    }
}

struct AuthTokenResponse: Decodable {
    let token: String
    let user: UserModel
}

struct UpdateProfileInfoResponse: Decodable {
    let user: UserModel
    let horoscope: HoroscopeModel?
}

private struct AuthSignUpBody: Encodable {
    let name: String
    let email: String
    let password: String
}

private struct AuthSignInBody: Encodable {
    let email: String
    let password: String
}

private struct PasswordResetRequestBody: Encodable {
    let email: String
}

private struct PasswordResetBody: Encodable {
    let email: String
    let code: String
    let password: String
}

private struct EmailConfirmationBody: Encodable {
    let code: String
}

private struct AppleSignInBody: Encodable {
    let identityToken: String
    let authorizationCode: String?
    let nonce: String
    let name: String?
}

nonisolated private struct ServerErrorResponse: Decodable {
    let reason: String
}

nonisolated enum NetworkError: LocalizedError {
    case invalidURL, invalidResponse, decodingError, unauthorized, sessionExpired, userExists, notFound, tooManyRequests, serverUnavailable, timedOut, noConnection, cannotReachServer, cancelled
    case server(String), limited(String)

    init(statusCode: Int, data: Data) {
        if (500...599).contains(statusCode) {
            self = .serverUnavailable
            return
        }

        if let reason = try? JSONDecoder().decode(ServerErrorResponse.self, from: data).reason, !reason.isEmpty {
            self = statusCode == 429 ? .limited(reason) : .server(reason)
            return
        }

        switch statusCode {
            case 401:
                self = .unauthorized
            case 404:
                self = .notFound
            case 409:
                self = .userExists
            case 429:
                self = .tooManyRequests
            default:
                self = .invalidResponse
        }
    }

    init(urlError: URLError) {
        switch urlError.code {
            case .timedOut:
                self = .timedOut
            case .cancelled:
                self = .cancelled
            case .notConnectedToInternet, .networkConnectionLost:
                self = .noConnection
            default:
                self = .cannotReachServer
        }
    }

    var errorDescription: String? {
        switch self {
            case .invalidURL: "Некорректный URL"
            case .invalidResponse: "Некорректный ответ от сервера"
            case .decodingError: "Не удалось обработать ответ сервера"
            case .unauthorized: "Неправильная почта или пароль"
            case .sessionExpired: "Сессия истекла. Войдите снова"
            case .userExists: "Пользователь уже зарегистрирован"
            case .notFound: "Данные не найдены"
            case .tooManyRequests: "Слишком много запросов. Попробуйте позже"
            case .serverUnavailable: "Сервис временно недоступен. Попробуйте позже"
            case .server(let message), .limited(let message): message
            case .timedOut: "Сервер не ответил вовремя. Попробуйте ещё раз"
            case .noConnection: "Нет подключения к интернету"
            case .cannotReachServer: "Не удалось связаться с сервером. Попробуйте позже"
            case .cancelled: "Запрос отменён"
        }
    }
}
