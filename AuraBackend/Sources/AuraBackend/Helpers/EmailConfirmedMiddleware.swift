//
//  EmailConfirmedMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

// AI tests are limited per account, so an account must not cost nothing to create
struct EmailConfirmedMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let user = try req.auth.require(User.self)

        guard user.isEmailConfirmed else {
            throw Abort(.forbidden, reason: "Подтвердите почту, чтобы проходить тесты")
        }

        return try await next.respond(to: req)
    }
}
