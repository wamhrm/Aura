//
//  RequestLoggingMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

// Health checks come every few seconds and would bury the real requests in the log
struct RequestLoggingMiddleware: AsyncMiddleware {
    private let silentPaths: Set<String> = ["/health", "/ready"]

    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        if !silentPaths.contains(req.url.path) {
            req.logger.info("\(req.method) \(req.url.path)")
        }

        return try await next.respond(to: req)
    }
}
