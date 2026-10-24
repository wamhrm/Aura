//
//  NetworkHelper.swift
//  Aura
//
//  Created by ddorsat on 13.05.2026.
//

import Foundation

fileprivate enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

fileprivate enum RequestAuthorization {
    case none
    case storedToken
    case token(String)
}

protocol NetworkServiceProtocol: Sendable {
    var sessionExpiredEvents: AsyncStream<Void> { get }

    func createAccount(name: String, email: String, password: String) async throws
    func signIn(email: String, password: String) async throws -> AuthTokenResponse
    func signInWithApple(identityToken: String,
                         authorizationCode: String?,
                         nonce: String,
                         name: String?) async throws -> AuthTokenResponse
    func logout(token: String) async throws
    func deleteAccount() async throws
    func giveAIConsent() async throws -> UserModel
    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse
    func fetchCurrentHoroscope() async throws -> HoroscopeModel
    func fetchDailyInsight() async throws -> DailyContentModel
    func fetchDailyTip() async throws -> DailyContentModel
    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel
    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest) async throws -> CompabilityResultModel
    func fetchHistory() async throws -> [HistoryCellModel]
    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel
    func deleteHistory(id: UUID) async throws
}

nonisolated final class NetworkService: NetworkServiceProtocol {
    let sessionExpiredEvents: AsyncStream<Void>

    private let baseURL: String
    private let session: URLSession
    private let sessionExpiredContinuation: AsyncStream<Void>.Continuation

    private let tokenPath = Constants.tokenPath
    private let tokenKey = Constants.tokenKey

    private let keychain: any KeychainHelperProtocol

    init(baseURL: String = Constants.baseURL,
         session: URLSession = NetworkService.makeSession(),
         keychain: any KeychainHelperProtocol = KeychainHelper()) {
        self.baseURL = baseURL
        self.session = session
        self.keychain = keychain
        (sessionExpiredEvents, sessionExpiredContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 300
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let bodyData = try JSONEncoder().encode(AuthSignUpBody(name: name, email: email, password: password))
        _ = try await request(endpoint: "/auth/createAccount", method: .post, body: bodyData, authorization: .none)
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

    func deleteAccount() async throws {
        _ = try await request(endpoint: "/auth/account", method: .delete)
    }

    func giveAIConsent() async throws -> UserModel {
        let data = try await request(endpoint: "/auth/aiConsent", method: .post)
        return try decode(UserModel.self, from: data)
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let bodyData = try JSONEncoder().encode(profileInfo)
        let data = try await request(endpoint: "/auth/profileInfo", method: .patch, body: bodyData)
        return try decode(UpdateProfileInfoResponse.self, from: data)
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        let data = try await request(endpoint: "/horoscope/current", method: .get)
        return try decode(HoroscopeModel.self, from: data)
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/insight", method: .get)
        return try decode(DailyContentModel.self, from: data)
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/tip", method: .get)
        return try decode(DailyContentModel.self, from: data)
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        let bodyData = try JSONEncoder().encode(selectedTests)
        let data = try await request(endpoint: "/history/personality", method: .post, body: bodyData)
        return try decode(PersonalityResultModel.self, from: data)
    }

    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest) async throws -> CompabilityResultModel {
        let bodyData = try JSONEncoder().encode(testRequest)
        let data = try await request(endpoint: "/history/compatibility", method: .post, body: bodyData)
        return try decode(CompabilityResultModel.self, from: data)
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
                         attempt: Int = 0) async throws -> Data {
        do {
            return try await performRequest(endpoint: endpoint, method: method, body: body, authorization: authorization)
        } catch let urlError as URLError where method == .get && Self.isRetryable(urlError) && attempt < 2 {
            try await Task.sleep(for: Self.retryDelay(for: attempt))
            return try await request(endpoint: endpoint,
                                     method: method,
                                     body: body,
                                     authorization: authorization,
                                     attempt: attempt + 1)
        } catch let urlError as URLError {
            throw NetworkError(urlError: urlError)
        }
    }

    private func performRequest(endpoint: String,
                                method: HTTPMethod,
                                body: Data?,
                                authorization: RequestAuthorization) async throws -> Data {
        guard let baseURL = URL(string: baseURL),
              let url = URL(string: endpoint, relativeTo: baseURL)?.absoluteURL else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            urlRequest.httpBody = body
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
            case 401 where token != nil:
                sessionExpiredContinuation.yield()
                throw NetworkError.sessionExpired
            default:
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
                guard let tokenData = keychain.getToken(path: tokenPath, key: tokenKey) else { return nil }
                return String(data: tokenData, encoding: .utf8)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder().decode(type, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    private static func isRetryable(_ error: URLError) -> Bool {
        switch error.code {
            case .timedOut,
                 .networkConnectionLost,
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

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
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

private struct AppleSignInBody: Encodable {
    let identityToken: String
    let authorizationCode: String?
    let nonce: String
    let name: String?
}

nonisolated private struct ServerErrorResponse: Decodable {
    let reason: String
}

fileprivate enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case unauthorized
    case sessionExpired
    case userExists
    case notFound
    case tooManyRequests
    case serverUnavailable
    case server(String)
    case timedOut
    case noConnection
    case cannotReachServer

    init(statusCode: Int, data: Data) {
        if (500...599).contains(statusCode) {
            self = .serverUnavailable
            return
        }

        if let reason = try? JSONDecoder().decode(ServerErrorResponse.self, from: data).reason, !reason.isEmpty {
            self = .server(reason)
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
            case .notConnectedToInternet, .networkConnectionLost:
                self = .noConnection
            case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                self = .cannotReachServer
            default:
                self = .invalidResponse
        }
    }

    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "Некорректный URL"
            case .invalidResponse:
                return "Некорректный ответ от сервера"
            case .decodingError:
                return "Не удалось обработать ответ сервера"
            case .unauthorized:
                return "Неправильная почта или пароль"
            case .sessionExpired:
                return "Сессия истекла. Войдите снова"
            case .userExists:
                return "Пользователь уже зарегистрирован"
            case .notFound:
                return "Данные не найдены"
            case .tooManyRequests:
                return "Слишком много запросов. Попробуйте позже"
            case .serverUnavailable:
                return "Сервис временно недоступен. Попробуйте позже"
            case .server(let message):
                return message
            case .timedOut:
                return "Сервер просыпается дольше обычного. Попробуйте ещё раз через минуту"
            case .noConnection:
                return "Нет подключения к интернету"
            case .cannotReachServer:
                return "Не удалось связаться с сервером. Попробуйте позже"
        }
    }
}
