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
    case apiError(statusCode: Int, message: String)
    case decodingError
    case unauthorized(message: String)
    case conflict(message: String)

    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "Некорректный URL"
            case .invalidResponse:
                return "Некорректный ответ от сервера"
            case .apiError(_, let message):
                return message
            case .decodingError:
                return "Не удалось обработать ответ сервера"
            case .unauthorized(let message), .conflict(message: let message):
                return message
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

struct NetworkHelper {
    static func request<Response: Decodable>(endpoint: String,
                                             method: HTTPMethod,
                                             token: String? = nil) async throws -> Response {
        let request = try makeRequest(endpoint: endpoint, method: method, token: token)
        
        return try await perform(request)
    }

    static func request<Response: Decodable, Body: Encodable>(endpoint: String,
                                                              method: HTTPMethod,
                                                              body: Body,
                                                              token: String? = nil) async throws -> Response {
        var request = try makeRequest(endpoint: endpoint, method: method, token: token)
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await perform(request)
    }
    
    private static func makeRequest(endpoint: String,
                                    method: HTTPMethod,
                                    token: String?) throws -> URLRequest {
        guard let baseURL = URL(string: Constants.baseURL),
              let url = URL(string: endpoint, relativeTo: baseURL)?.absoluteURL else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private static func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(Response.self, from: data)
                } catch {
                    throw NetworkError.decodingError
                }
            case 401:
                throw NetworkError.unauthorized(
                    message: errorMessage(from: data) ?? "Неправильная почта или пароль"
                )
            case 409:
                throw NetworkError.conflict(
                    message: errorMessage(from: data) ?? "Пользователь уже зарегистрирован"
                )
            default:
                let message = errorMessage(from: data) ?? "Ошибка сервера: \(httpResponse.statusCode)"
                throw NetworkError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private static func errorMessage(from data: Data) -> String? {
        try? JSONDecoder().decode(APIErrorResponse.self, from: data).reason
    }
}


private struct APIErrorResponse: Decodable {
    let reason: String
}
