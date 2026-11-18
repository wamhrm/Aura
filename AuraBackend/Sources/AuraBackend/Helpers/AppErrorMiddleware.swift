//
//  AppErrorMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import AsyncHTTPClient
import PostgresNIO
import Vapor

struct AppErrorMiddleware: AsyncMiddleware {
    private struct ErrorBody: Content {
        let error: Bool
        let reason: String
    }

    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: req)
        } catch {
            return try await makeResponse(error: error, req: req)
        }
    }

    private func makeResponse(error: any Error, req: Request) async throws -> Response {
        let abort = error as? any AbortError
        let status = abort?.status ?? .internalServerError

        if status.code >= 500 {
            let route = req.route?.description ?? "unmatched route"
            req.logger.error("\(route) failed with status \(status.code): \(errorLogCode(error))")
        }

        let body = ErrorBody(error: true, reason: reason(abort: abort, status: status))
        let response = try await body.encodeResponse(status: status, for: req)

        if let headers = abort?.headers {
            response.headers.add(contentsOf: headers)
        }

        return response
    }

    private func reason(abort: (any AbortError)?, status: HTTPResponseStatus) -> String {
        if status.code < 500, let reason = abort?.reason, reason != status.reasonPhrase {
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
}

func errorLogCode(_ error: any Error) -> String {
    if let error = error as? PSQLError {
        if let sqlState = error.serverInfo?[.sqlState] {
            return "PostgreSQL \(error.code) (SQLSTATE \(sqlState))"
        }
        return "PostgreSQL \(error.code)"
    }
    if let error = error as? HTTPClientError {
        return error.shortDescription
    }
    if let error = error as? URLError {
        return "URLError \(error.errorCode)"
    }
    return String(describing: type(of: error))
}
