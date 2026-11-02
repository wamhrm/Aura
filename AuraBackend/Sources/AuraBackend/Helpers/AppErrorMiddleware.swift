//
//  AppErrorMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

// Every error leaves as {"error": true, "reason": "..."} with a Russian text the app can show as is
struct AppErrorMiddleware: AsyncMiddleware {
    private struct ErrorBody: Content {
        let error: Bool
        let reason: String
    }

    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: req)
        } catch {
            return try await makeResponse(for: error, on: req)
        }
    }

    private func makeResponse(for error: any Error, on req: Request) async throws -> Response {
        let abort = error as? any AbortError
        let status = abort?.status ?? .internalServerError

        if status.code >= 500 {
            req.logger.error("Request failed with status \(status.code): \(String(reflecting: error))")
        }

        let body = ErrorBody(error: true, reason: reason(for: abort, status: status))
        let response = try await body.encodeResponse(status: status, for: req)

        if let headers = abort?.headers {
            response.headers.add(contentsOf: headers)
        }

        return response
    }

    private func reason(for abort: (any AbortError)?, status: HTTPResponseStatus) -> String {
        // Details of a server failure stay in the log. Framework errors come in English.
        if status.code < 500, let reason = abort?.reason, containsRussianText(reason) {
            return reason
        }

        switch status.code {
            case 400:
                return "Некорректные данные запроса"
            case 401:
                return "Требуется вход в аккаунт"
            case 403:
                return "Доступ запрещён"
            case 404:
                return "Не найдено"
            case 429:
                return "Слишком много запросов. Попробуйте позже"
            case 500...:
                return "Сервис временно недоступен. Попробуйте позже"
            default:
                return "Не удалось выполнить запрос"
        }
    }

    private func containsRussianText(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
    }
}
