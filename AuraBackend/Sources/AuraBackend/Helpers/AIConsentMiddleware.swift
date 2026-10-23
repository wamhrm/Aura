//
//  AIConsentMiddleware.swift
//  AuraBackend
//
//  Created by ddorsat on 23.10.2026.
//

import Vapor

struct AIConsentMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let user = try req.auth.require(User.self)

        guard user.aiConsentAt != nil else {
            throw Abort(.forbidden, reason: "Разрешите анализ с помощью AI, чтобы пользоваться этой функцией")
        }

        return try await next.respond(to: req)
    }
}
