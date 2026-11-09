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
    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse
    func signIn(email: String, password: String) async throws -> AuthTokenResponse
    func logout() async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse
    func deleteAccount() async throws
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
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 300
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse {
        let body = try JSONEncoder().encode(AuthSignUpBody(name: name, email: email, password: password))
        return try await fetch(endpoint: "/auth/createAccount", method: .post, body: body)
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        let body = try JSONEncoder().encode(AuthSignInBody(email: email, password: password))
        return try await fetch(endpoint: "/auth/signIn", method: .post, body: body)
    }

    func logout() async throws {
        _ = try await send(endpoint: "/auth/logout", method: .post)
    }

    func requestPasswordReset(email: String) async throws {
        let body = try JSONEncoder().encode(PasswordResetRequestBody(email: email))
        _ = try await send(endpoint: "/auth/password/forgot", method: .post, body: body)
    }

    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse {
        let body = try JSONEncoder().encode(PasswordResetBody(email: email, code: code, password: password))
        return try await fetch(endpoint: "/auth/password/reset", method: .post, body: body)
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

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let body = try JSONEncoder().encode(profileInfo)
        return try await fetch(endpoint: "/auth/profileInfo", method: .patch, body: body)
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        try await fetch(endpoint: "/horoscope/current", method: .get, timeout: Self.aiTimeout)
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        try await fetch(endpoint: "/daily/insight", method: .get, timeout: Self.aiTimeout)
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        try await fetch(endpoint: "/daily/tip", method: .get, timeout: Self.aiTimeout)
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
                                     idempotencyKey: UUID? = nil,
                                     timeout: TimeInterval = NetworkService.defaultTimeout) async throws -> T {
        let data = try await send(endpoint: endpoint,
                                  method: method,
                                  body: body,
                                  idempotencyKey: idempotencyKey,
                                  timeout: timeout)
        return try decode(T.self, data: data)
    }

    private func send(endpoint: String,
                      method: HTTPMethod,
                      body: Data? = nil,
                      idempotencyKey: UUID? = nil,
                      timeout: TimeInterval = NetworkService.defaultTimeout,
                      attempt: Int = 0) async throws -> Data {
        do {
            return try await performRequest(endpoint: endpoint,
                                            method: method,
                                            body: body,
                                            idempotencyKey: idempotencyKey,
                                            timeout: timeout)
        } catch let urlError as URLError where method == .get && Self.isRetryable(urlError, timeout: timeout) && attempt < 2 {
            try await Task.sleep(for: Self.retryDelay(attempt: attempt))
            return try await send(endpoint: endpoint,
                                  method: method,
                                  body: body,
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
        urlRequest.httpBody = body

        if let idempotencyKey {
            urlRequest.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "Idempotency-Key")
        }

        let token = try? keychain.loadAuthToken()
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
                throw NetworkError(statusCode: httpResponse.statusCode, data: data)
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
