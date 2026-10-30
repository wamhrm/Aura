//
//  UserAuthMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct UserAuthMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let tokenString = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Токен не найден")
        }

        guard let tokenModel = try await Token.query(on: req.db)
            .filter(\.$value == Token.hash(tokenString))
            .with(\.$user)
            .first()
        else { throw Abort(.unauthorized, reason: "Неверный токен") }

        let now = Date()

        guard tokenModel.expiresAt > now else {
            try await tokenModel.delete(on: req.db)
            throw Abort(.unauthorized, reason: "Срок действия токена истёк")
        }

        if tokenModel.expiresAt < now.addingTimeInterval(Token.lifetime - Token.renewalInterval) {
            tokenModel.expiresAt = now.addingTimeInterval(Token.lifetime)
            try await tokenModel.save(on: req.db)
        }

        req.auth.login(tokenModel.user)
        req.auth.login(tokenModel)

        return try await next.respond(to: req)
    }
}
