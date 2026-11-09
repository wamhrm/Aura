//
//  AuthController.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct AuthController: RouteCollection {
    private let emailCodeService = EmailCodeService()

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        let limited = auth.grouped(RateLimitMiddleware(limit: 10, window: 60))
        limited.post("createAccount", use: createAccount)
        limited.post("signIn", use: signIn)
        limited.post("password", "forgot", use: requestPasswordReset)
        limited.post("password", "reset", use: resetPassword)

        let authenticated = auth.grouped(UserAuthMiddleware())
        authenticated.post("logout", use: logout)
        authenticated.delete("account", use: deleteAccount)
        authenticated.post("email", "sendCode", use: sendEmailConfirmationCode)
        authenticated.post("email", "confirm", use: confirmEmail)
    }

    private func createAccount(req: Request) async throws -> Response {
        let data = try req.content.decode(CreateAccountRequest.self)
        let name = data.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = normalizedEmail(email: data.email)

        guard name.count >= InputLimits.minNameLength else {
            throw Abort(.badRequest, reason: "Имя должно содержать минимум 2 символа")
        }
        guard name.count <= InputLimits.maxNameLength else {
            throw Abort(.badRequest, reason: "Имя должно быть не длиннее 50 символов")
        }
        guard email.count <= InputLimits.maxEmailLength, isValidEmail(email: email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }
        try validatePassword(password: data.password)

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

        return try await issueToken(user: user, database: req.db).encodeResponse(status: .created, for: req)
    }

    private func signIn(req: Request) async throws -> AuthDTO {
        let signInData = try req.content.decode(SignInRequest.self)
        let email = normalizedEmail(email: signInData.email)

        guard let user = try await User.query(on: req.db)
            .filter(\User.$email == email)
            .first(),
              let passwordHash = user.passwordHash
        else { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        let isPasswordCorrect = try await req.password.async.verify(signInData.password, created: passwordHash)

        if !isPasswordCorrect { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        return try await issueToken(user: user, database: req.db)
    }

    private func requestPasswordReset(req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(ForgotPasswordRequest.self)
        let email = normalizedEmail(email: data.email)

        guard email.count <= InputLimits.maxEmailLength, isValidEmail(email: email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }

        if let user = try await User.query(on: req.db).filter(\.$email == email).first(), user.passwordHash != nil {
            try await emailCodeService.sendReset(user: user, req: req)
        }

        return .noContent
    }

    private func resetPassword(req: Request) async throws -> AuthDTO {
        let data = try req.content.decode(ResetPasswordRequest.self)
        let email = normalizedEmail(email: data.email)
        try validatePassword(password: data.password)

        guard let user = try await User.query(on: req.db).filter(\.$email == email).first(),
              user.passwordHash != nil
        else { throw Abort(.badRequest, reason: "Код недействителен. Запросите новый") }

        try await emailCodeService.verifyReset(code: data.code.trimmingCharacters(in: .whitespacesAndNewlines),
                                               user: user,
                                               req: req)

        let userID = try user.requireID()
        user.passwordHash = try await req.password.async.hash(data.password)
        user.emailConfirmedAt = user.emailConfirmedAt ?? Date()
        try await user.save(on: req.db)
        try await Token.query(on: req.db).filter(\.$user.$id == userID).delete()
        try await PasswordReset.query(on: req.db).filter(\.$user.$id == userID).delete()
        return try await issueToken(user: user, database: req.db)
    }

    private func sendEmailConfirmationCode(req: Request) async throws -> HTTPStatus {
        try await emailCodeService.sendConfirmation(user: try req.auth.require(User.self), req: req)
        return .noContent
    }

    private func confirmEmail(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        let data = try req.content.decode(ConfirmEmailRequest.self)

        try await emailCodeService.confirm(code: data.code.trimmingCharacters(in: .whitespacesAndNewlines),
                                           user: user,
                                           req: req)

        return try user.toDTO()
    }

    private func issueToken(user: User, database: any Database) async throws -> AuthDTO {
        let userID = try user.requireID()

        try await Token.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$expiresAt < Date())
            .delete()

        let tokenValue = [UInt8].random(count: 32).base64
        let token = Token(value: Token.hash(value: tokenValue),
                          userID: userID,
                          expiresAt: Date().addingTimeInterval(Token.lifetime))
        try await token.save(on: database)

        return AuthDTO(token: tokenValue, user: try user.toDTO())
    }

    private func logout(req: Request) async throws -> HTTPStatus {
        let token = try req.auth.require(Token.self)
        try await token.delete(on: req.db)
        return .noContent
    }

    private func deleteAccount(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        try await user.delete(on: req.db)
        return .noContent
    }

    private func validatePassword(password: String) throws {
        guard password.count >= InputLimits.minPasswordLength else {
            throw Abort(.badRequest, reason: "Пароль должен быть не короче \(InputLimits.minPasswordLength) символов")
        }
        guard password.utf8.count <= InputLimits.maxPasswordBytes else {
            throw Abort(.badRequest, reason: "Пароль слишком длинный")
        }
    }

    private func normalizedEmail(email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let local = parts[0]
        let domain = parts[1]
        return !local.isEmpty && !domain.isEmpty
    }
}
