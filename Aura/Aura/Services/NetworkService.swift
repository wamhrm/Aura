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

struct NetworkService {
    private static let tokenPath = Constants.tokenPath
    private static let tokenKey = Constants.tokenKey

    static func createAccount(name: String, email: String, password: String) async throws {
        let bodyData = try JSONEncoder().encode(AuthSignUpBody(name: name, email: email, password: password))
        _ = try await request(endpoint: "/auth/createAccount", method: .post, body: bodyData)
    }

    static func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        let bodyData = try JSONEncoder().encode(AuthSignInBody(email: email, password: password))
        let data = try await request(endpoint: "/auth/signIn", method: .post, body: bodyData)
        return try decoder().decode(AuthTokenResponse.self, from: data)
    }

    static func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UpdateProfileInfoResponse {
        let bodyData = try JSONEncoder().encode(profileInfo)
        let data = try await request(endpoint: "/auth/profileInfo", method: .patch, body: bodyData)
        return try decoder().decode(UpdateProfileInfoResponse.self, from: data)
    }

    static func fetchCurrentHoroscope() async throws -> HoroscopeModel {
        let data = try await request(endpoint: "/horoscope/current", method: .get)
        return try decoder().decode(HoroscopeModel.self, from: data)
    }

    static func fetchDailyInsight() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/insight", method: .get)
        return try decoder().decode(DailyContentModel.self, from: data)
    }

    static func fetchDailyTip() async throws -> DailyContentModel {
        let data = try await request(endpoint: "/daily/tip", method: .get)
        return try decoder().decode(DailyContentModel.self, from: data)
    }

    static func makePersonalityTest(selectedTests: [PersonalityTestTypes]) async throws -> PersonalityResultModel {
        let bodyData = try JSONEncoder().encode(selectedTests)
        let data = try await request(endpoint: "/history/personality", method: .post, body: bodyData)
        return try decoder().decode(PersonalityResultModel.self, from: data)
    }

    static func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest) async throws -> CompabilityResultModel {
        let bodyData = try JSONEncoder().encode(testRequest)
        let data = try await request(endpoint: "/history/compatibility", method: .post, body: bodyData)
        return try decoder().decode(CompabilityResultModel.self, from: data)
    }

    static func fetchHistory() async throws -> [HistoryCellModel] {
        let data = try await request(endpoint: "/history", method: .get)
        return try decoder().decode([HistoryCellModel].self, from: data)
    }

    static func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        let data = try await request(endpoint: "/history/\(id.uuidString)", method: .get)
        return try decoder().decode(HistoryCellModel.self, from: data)
    }

    static func deleteHistory(id: UUID) async throws {
        _ = try await request(endpoint: "/history/\(id.uuidString)", method: .delete)
    }

    private static func request(endpoint: String,
                                method: HTTPMethod,
                                body: Data? = nil,
                                attempt: Int = 0) async throws -> Data {
        do {
            return try await performRequest(endpoint: endpoint, method: method, body: body)
        } catch let urlError as URLError where urlError.code == .networkConnectionLost && attempt < 2 {
            try await Task.sleep(for: .milliseconds(500))
            return try await request(endpoint: endpoint, method: method, body: body, attempt: attempt + 1)
        }
    }

    private static func performRequest(endpoint: String,
                                       method: HTTPMethod,
                                       body: Data? = nil) async throws -> Data {
        guard let baseURL = URL(string: Constants.baseURL),
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

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

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

    private static func decoder() -> JSONDecoder {
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
        }
    }
}
