//
//  NetworkHelper.swift
//  Aura
//
//  Created by ddorsat on 13.05.2026.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case unauthorized
    case conflict

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
            case .conflict:
                return "Пользователь уже зарегистрирован"
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

struct NetworkHelper {
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

    static func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UserModel {
        let bodyData = try JSONEncoder().encode(profileInfo)
        let data = try await request(endpoint: "/auth/profileInfo", method: .patch, body: bodyData)
        return try decoder().decode(UserModel.self, from: data)
    }

    static func generatePersonality(selectedTests: [TestTypes]) async throws -> PersonalityResult {
        let bodyData = try JSONEncoder().encode(selectedTests)
        let data = try await request(endpoint: "/personality/generate", method: .post, body: bodyData)
        return try decoder().decode(PersonalityResult.self, from: data)
    }

    private static func request(endpoint: String, method: HTTPMethod, body: Data) async throws -> Data {
        guard let baseURL = URL(string: Constants.baseURL),
              let url = URL(string: endpoint, relativeTo: baseURL)?.absoluteURL else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        if let tokenData = KeychainHelper.standard.read(path: tokenPath, key: tokenKey),
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
                throw NetworkError.conflict
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

private struct AuthSignUpBody: Encodable {
    let name: String
    let email: String
    let password: String
}

private struct AuthSignInBody: Encodable {
    let email: String
    let password: String
}

private struct APIErrorResponse: Decodable {
    let reason: String
}
