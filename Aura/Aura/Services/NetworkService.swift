//
//  NetworkService.swift
//  Aura
//
//  Created by wamhrm on 13.05.2026.
//

import Foundation

fileprivate enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol NetworkServiceProtocol: Sendable {
    func fetchCurrentUser() async throws -> UserModel
    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse
    func ensureEmailAvailable(email: String) async throws
    func signIn(email: String, password: String) async throws -> AuthTokenResponse
    func logout() async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse
    func deleteAccount() async throws
    func giveAIConsent() async throws -> UserModel
    func sendEmailConfirmationCode() async throws
    func confirmEmail(code: String) async throws -> UserModel
    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UserModel
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
    private static let defaultTimeout: TimeInterval = 20
    private static let aiTimeout: TimeInterval = 130

    private let baseURL: String
    private let session: URLSession
    private let keychain: any KeychainHelperProtocol

    init(baseURL: String = Constants.baseURL,
         session: URLSession = NetworkService.makeSession(),
         keychain: any KeychainHelperProtocol = KeychainHelper()) {
        self.baseURL = baseURL
        self.session = session
        self.keychain = keychain
    }

    private static func makeSession() -> URLSession {
        URLCache.shared.removeAllCachedResponses()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 300
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func fetchCurrentUser() async throws -> UserModel {
        try await fetch(endpoint: "/auth/me", method: .get)
    }

    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse {
        let body = try JSONEncoder().encode(AuthSignUpBody(name: name, email: email, password: password))
        return try await fetch(endpoint: "/auth/createAccount", method: .post, body: body, requiresAuth: false)
    }

    func ensureEmailAvailable(email: String) async throws {
        let body = try JSONEncoder().encode(EmailBody(email: email))
        _ = try await send(endpoint: "/auth/email/available", method: .post, body: body, requiresAuth: false)
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        let body = try JSONEncoder().encode(AuthSignInBody(email: email, password: password))
        return try await fetch(endpoint: "/auth/signIn", method: .post, body: body, requiresAuth: false)
    }

    func logout() async throws {
        _ = try await send(endpoint: "/auth/logout", method: .post)
    }

    func requestPasswordReset(email: String) async throws {
        let body = try JSONEncoder().encode(EmailBody(email: email))
        _ = try await send(endpoint: "/auth/password/forgot", method: .post, body: body, requiresAuth: false)
    }

    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse {
        let body = try JSONEncoder().encode(PasswordResetBody(email: email, code: code, password: password))
        return try await fetch(endpoint: "/auth/password/reset", method: .post, body: body, requiresAuth: false)
    }

    func deleteAccount() async throws {
        _ = try await send(endpoint: "/auth/account", method: .delete)
    }

    func giveAIConsent() async throws -> UserModel {
        try await fetch(endpoint: "/auth/aiConsent", method: .post)
    }

    func sendEmailConfirmationCode() async throws {
        _ = try await send(endpoint: "/auth/email/sendCode", method: .post)
    }

    func confirmEmail(code: String) async throws -> UserModel {
        let body = try JSONEncoder().encode(EmailConfirmationBody(code: code))
        return try await fetch(endpoint: "/auth/email/confirm", method: .post, body: body)
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UserModel {
        let body = try JSONEncoder().encode(profileInfo)
        let response: UpdateProfileInfoResponse = try await fetch(endpoint: "/auth/profileInfo", method: .patch, body: body)
        return response.user
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        try await fetch(endpoint: "/horoscope/current", method: .get, timeout: Self.aiTimeout, retries: false)
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        try await fetch(endpoint: "/daily/insight", method: .get, timeout: Self.aiTimeout, retries: false)
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        try await fetch(endpoint: "/daily/tip", method: .get, timeout: Self.aiTimeout, retries: false)
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel {
        let body = try JSONEncoder().encode(selectedTests)
        return try await fetch(endpoint: "/history/personality",
                               method: .post,
                               body: body,
                               idempotencyKey: requestID,
                               timeout: Self.aiTimeout)
    }

    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel {
        let body = try JSONEncoder().encode(testRequest)
        return try await fetch(endpoint: "/history/compatibility",
                               method: .post,
                               body: body,
                               idempotencyKey: requestID,
                               timeout: Self.aiTimeout)
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        try await fetch(endpoint: "/history", method: .get)
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await fetch(endpoint: "/history/\(id.uuidString)", method: .get)
    }

    func deleteHistory(id: UUID) async throws {
        _ = try await send(endpoint: "/history/\(id.uuidString)", method: .delete)
    }

    private func fetch<T: Decodable>(endpoint: String,
                                     method: HTTPMethod,
                                     body: Data? = nil,
                                     requiresAuth: Bool = true,
                                     idempotencyKey: UUID? = nil,
                                     timeout: TimeInterval = NetworkService.defaultTimeout,
                                     retries: Bool = true) async throws -> T {
        let data = try await send(endpoint: endpoint,
                                  method: method,
                                  body: body,
                                  requiresAuth: requiresAuth,
                                  idempotencyKey: idempotencyKey,
                                  timeout: timeout,
                                  retries: retries)
        return try decode(T.self, data: data)
    }

    private func send(endpoint: String,
                      method: HTTPMethod,
                      body: Data? = nil,
                      requiresAuth: Bool = true,
                      idempotencyKey: UUID? = nil,
                      timeout: TimeInterval = NetworkService.defaultTimeout,
                      retries: Bool = true,
                      attempt: Int = 0) async throws -> Data {
        do {
            return try await performRequest(endpoint: endpoint,
                                            method: method,
                                            body: body,
                                            requiresAuth: requiresAuth,
                                            idempotencyKey: idempotencyKey,
                                            timeout: timeout)
        } catch let urlError as URLError where retries && method == .get
                    && Self.isRetryable(urlError, timeout: timeout)
                    && attempt < 2 {
            try await Task.sleep(for: Self.retryDelay(attempt: attempt))
            return try await send(endpoint: endpoint,
                                  method: method,
                                  body: body,
                                  requiresAuth: requiresAuth,
                                  idempotencyKey: idempotencyKey,
                                  timeout: timeout,
                                  retries: retries,
                                  attempt: attempt + 1)
        } catch let urlError as URLError {
            throw NetworkError(urlError: urlError)
        }
    }

    private func performRequest(endpoint: String,
                                method: HTTPMethod,
                                body: Data?,
                                requiresAuth: Bool,
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
        urlRequest.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Time-Zone")
        urlRequest.setValue(AppLanguage.requestCode, forHTTPHeaderField: "Accept-Language")
        urlRequest.httpBody = body

        if let idempotencyKey {
            urlRequest.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "Idempotency-Key")
        }

        let token = requiresAuth ? try keychain.loadAuthToken() : nil
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
                if token != nil {
                    throw NetworkError.sessionExpired
                }

                throw NetworkError(statusCode: httpResponse.statusCode, data: data)
            default:
                throw NetworkError(statusCode: httpResponse.statusCode, data: data,
                                   code: httpResponse.value(forHTTPHeaderField: "X-Aura-Error-Code"))
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    private static func isRetryable(_ error: URLError, timeout: TimeInterval) -> Bool {
        switch error.code {
            case .timedOut:
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

    private static func retryDelay(attempt: Int) -> Duration {
        .seconds(Double(attempt) + 0.5)
    }
}

struct AuthTokenResponse: Decodable {
    let token: String
    let user: UserModel
}

private struct UpdateProfileInfoResponse: Decodable {
    let user: UserModel
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

private struct EmailBody: Encodable {
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

nonisolated private struct ServerErrorResponse: Decodable {
    let reason: String
}

nonisolated enum NetworkError: LocalizedError {
    case invalidURL, invalidResponse, decodingError, unauthorized, sessionExpired, userExists, notFound, tooManyRequests, serverUnavailable, timedOut, noConnection, cannotReachServer, cancelled
    case server(String), limited(String)
    case emailCodeRecentlyRequested(String), emailCodeDailyLimit(String)

    init(statusCode: Int, data: Data, code: String? = nil) {
        if (500...599).contains(statusCode) {
            self = .serverUnavailable
            return
        }

        if let reason = try? JSONDecoder().decode(ServerErrorResponse.self, from: data).reason, !reason.isEmpty {
            if statusCode == 429 {
                switch code {
                    case "email_code_recently_requested": self = .emailCodeRecentlyRequested(reason)
                    case "email_code_daily_limit": self = .emailCodeDailyLimit(reason)
                    default: self = .limited(reason)
                }
            } else {
                self = .server(reason)
            }
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
            case .invalidURL: AppLanguage.text("Некорректный URL")
            case .invalidResponse: AppLanguage.text("Некорректный ответ от сервера")
            case .decodingError: AppLanguage.text("Не удалось обработать ответ сервера")
            case .unauthorized: AppLanguage.text("Неправильная почта или пароль")
            case .sessionExpired: AppLanguage.text("Сессия истекла. Войдите снова")
            case .userExists: AppLanguage.text("Пользователь уже зарегистрирован")
            case .notFound: AppLanguage.text("Данные не найдены")
            case .tooManyRequests: AppLanguage.text("Слишком много запросов. Попробуйте позже")
            case .serverUnavailable: AppLanguage.text("Сервис временно недоступен. Попробуйте позже")
            case .server(let message), .limited(let message),
                 .emailCodeRecentlyRequested(let message), .emailCodeDailyLimit(let message): message
            case .timedOut: AppLanguage.text("Сервер не ответил вовремя. Попробуйте ещё раз")
            case .noConnection: AppLanguage.text("Нет подключения к интернету")
            case .cannotReachServer: AppLanguage.text("Не удалось связаться с сервером. Попробуйте позже")
            case .cancelled: AppLanguage.text("Запрос отменён")
        }
    }
}
