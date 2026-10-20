//
//  AuthController.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        let limited = auth.grouped(RateLimitMiddleware(limit: 10, window: 60))
        limited.post("createAccount", use: createAccount)
        limited.post("signIn", use: signIn)

        let authenticated = auth.grouped(UserAuthMiddleware())
        authenticated.post("logout", use: logout)
        authenticated.delete("account", use: deleteAccount)
    }

    private func createAccount(_ req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(CreateAccountRequest.self)
        let name = data.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = normalizedEmail(data.email)

        guard name.count >= InputLimits.minNameLength else {
            throw Abort(.badRequest, reason: "Имя должно содержать минимум 2 символа")
        }
        guard name.count <= InputLimits.maxNameLength else {
            throw Abort(.badRequest, reason: "Имя должно быть не длиннее 50 символов")
        }
        guard email.count <= InputLimits.maxEmailLength, isValidEmail(email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }
        guard data.password.count >= InputLimits.minPasswordLength else {
            throw Abort(.badRequest, reason: "Пароль должен быть не короче 6 символов")
        }
        guard data.password.utf8.count <= InputLimits.maxPasswordBytes else {
            throw Abort(.badRequest, reason: "Пароль слишком длинный")
        }

        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first()

        if existingUser != nil { throw Abort(.conflict, reason: "Пользователь уже зарегистрирован") }

        let digest = try await req.password.async.hash(data.password)
        let user = User(name: name, email: email, passwordHash: digest)

        do {
            try await user.save(on: req.db)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            throw Abort(.conflict, reason: "Пользователь уже зарегистрирован")
        }

        return .created
    }

    private func signIn(_ req: Request) async throws -> AuthDTO {
        let signInData = try req.content.decode(SignInRequest.self)
        let email = normalizedEmail(signInData.email)

        guard let user = try await User.query(on: req.db)
            .filter(\User.$email == email)
            .first()
        else { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        let isPasswordCorrect = try await req.password.async.verify(signInData.password, created: user.passwordHash)

        if !isPasswordCorrect { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        let userID = try user.requireID()

        try await Token.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$expiresAt < Date())
            .delete()

        let tokenValue = [UInt8].random(count: 32).base64
        let token = Token(value: Token.hash(tokenValue),
                          userID: userID,
                          expiresAt: Date().addingTimeInterval(Token.lifetime))
        try await token.save(on: req.db)

        return AuthDTO(token: tokenValue, user: try user.toDTO())
    }

    private func logout(_ req: Request) async throws -> HTTPStatus {
        let token = try req.auth.require(Token.self)
        try await token.delete(on: req.db)
        return .noContent
    }

    private func deleteAccount(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        try await user.delete(on: req.db)
        return .noContent
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let local = parts[0]
        let domain = parts[1]
        return !local.isEmpty && !domain.isEmpty
    }
}
