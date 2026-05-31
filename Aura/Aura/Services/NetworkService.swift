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

protocol NetworkServiceProtocol: Sendable {
    func createAccount(name: String, email: String, password: String) async throws
    func signIn(email: String, password: String) async throws -> AuthTokenResponse
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
    private let baseURL: String
    private let session: URLSession

    private let tokenPath = Constants.tokenPath
    private let tokenKey = Constants.tokenKey

    init(baseURL: String = Constants.baseURL,
         session: URLSession = NetworkService.makeSession()) {
        self.baseURL = baseURL
        self.session = session
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
        _ = try await request(endpoint: "/auth/createAccount", method: .post, body: bodyData)
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        let bodyData = try JSONEncoder().encode(AuthSignInBody(email: email, password: password))
        let data = try await request(endpoint: "/auth/signIn", method: .post, body: bodyData)
        return try decoder().decode(AuthTokenResponse.self, from: data)
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let bodyData = try JSONEncoder().encode(profileInfo)
        let data = try await request(endpoint: "/auth/profileInfo", method: .patch, body: bodyData)
        return try decoder().decode(UpdateProfileInfoResponse.self, from: data)
    }

    func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        let data = try await request(endpoint: "/horoscope/current", method: .get)
        return try decoder().decode(HoroscopeModel.self, from: data)
    }

    func fetchDailyInsight() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/insight", method: .get)
        return try decoder().decode(DailyContentModel.self, from: data)
    }

    func fetchDailyTip() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/tip", method: .get)
        return try decoder().decode(DailyContentModel.self, from: data)
    }

    func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        let bodyData = try JSONEncoder().encode(selectedTests)
        let data = try await request(endpoint: "/history/personality", method: .post, body: bodyData)
        return try decoder().decode(PersonalityResultModel.self, from: data)
    }

    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest) async throws -> CompabilityResultModel {
        let bodyData = try JSONEncoder().encode(testRequest)
        let data = try await request(endpoint: "/history/compatibility", method: .post, body: bodyData)
        return try decoder().decode(CompabilityResultModel.self, from: data)
    }

    func fetchHistory() async throws -> [HistoryCellModel] {
        let data = try await request(endpoint: "/history", method: .get)
        return try decoder().decode([HistoryCellModel].self, from: data)
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        let data = try await request(endpoint: "/history/\(id.uuidString)", method: .get)
        return try decoder().decode(HistoryCellModel.self, from: data)
    }

    func deleteHistory(id: UUID) async throws {
        _ = try await request(endpoint: "/history/\(id.uuidString)", method: .delete)
    }

    private func request(endpoint: String,
                         method: HTTPMethod,
                         body: Data? = nil,
                         attempt: Int = 0) async throws -> Data {
        do {
            return try await performRequest(endpoint: endpoint, method: method, body: body)
        } catch let urlError as URLError where Self.isRetryable(urlError) && attempt < 2 {
            try await Task.sleep(for: Self.retryDelay(for: attempt))
            return try await request(endpoint: endpoint, method: method, body: body, attempt: attempt + 1)
        } catch let urlError as URLError {
            throw NetworkError(urlError: urlError)
        }
    }

    private func performRequest(endpoint: String,
                                method: HTTPMethod,
                                body: Data? = nil) async throws -> Data {
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

        if let tokenData = KeychainHelper.standard.getToken(path: tokenPath, key: tokenKey),
           let token = String(data: tokenData, encoding: .utf8) {
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
                throw NetworkError.unauthorized
            case 409:
                throw NetworkError.userExists
            case 404:
                throw NetworkError.notFound
            default:
                throw NetworkError.invalidResponse
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
    let horoscope: HoroscopeModel
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

fileprivate enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case unauthorized
    case userExists
    case notFound
    case timedOut
    case noConnection
    case cannotReachServer

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
            case .userExists:
                return "Пользователь уже зарегистрирован"
            case .notFound:
                return "Пользователь не найден"
            case .timedOut:
                return "Сервер просыпается дольше обычного. Попробуйте ещё раз через минуту"
            case .noConnection:
                return "Нет подключения к интернету"
            case .cannotReachServer:
                return "Не удалось связаться с сервером. Попробуйте позже"
        }
    }
}
