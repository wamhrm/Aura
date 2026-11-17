//
//  AuthController.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import FluentSQL
import Vapor

struct AuthController: RouteCollection {
    private let emailCodeService = EmailCodeService()

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("createAccount", use: createAccount)
        auth.post("email", "available", use: checkEmailAvailable)
        auth.post("signIn", use: signIn)
        auth.post("password", "forgot", use: requestPasswordReset)
        auth.post("password", "reset", use: resetPassword)

        let authenticated = auth.grouped(UserAuthMiddleware())
        authenticated.get("me", use: fetchCurrentUser)
        authenticated.post("logout", use: logout)
        authenticated.delete("account", use: deleteAccount)
        authenticated.post("email", "sendCode", use: sendEmailConfirmationCode)
        authenticated.post("email", "confirm", use: confirmEmail)
    }

    private func fetchCurrentUser(req: Request) throws -> UserDTO {
        try req.auth.require(User.self).toDTO()
    }

    private func createAccount(req: Request) async throws -> Response {
        let data = try req.content.decode(CreateAccountRequest.self)
        let name = data.name.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
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

        if try await emailExists(email, database: req.db) {
            throw Abort(.conflict, reason: "Пользователь уже зарегистрирован")
        }

        let digest = try await req.password.async.hash(data.password)
        let user = User(name: name, email: email, passwordHash: digest)

        do {
            try await user.save(on: req.db)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            throw Abort(.conflict, reason: "Пользователь уже зарегистрирован")
        }

        return try await issueToken(user: user, database: req.db).encodeResponse(status: .created, for: req)
    }

    private func checkEmailAvailable(req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(EmailAvailabilityRequest.self)
        let email = normalizedEmail(email: data.email)

        guard email.count <= InputLimits.maxEmailLength, isValidEmail(email: email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }

        if try await emailExists(email, database: req.db) {
            throw Abort(.conflict, reason: "Пользователь уже зарегистрирован")
        }

        return .noContent
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

        return try await req.db.transaction { db in
            guard let currentUser = try await lockedUser(email: email, db: db),
                  currentUser.id == user.id, currentUser.passwordHash == passwordHash else {
                throw Abort(.unauthorized, reason: "Неверная почта или пароль")
            }
            return try await issueToken(user: currentUser, database: db)
        }
    }

    private func requestPasswordReset(req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(ForgotPasswordRequest.self)
        let email = normalizedEmail(email: data.email)

        guard email.count <= InputLimits.maxEmailLength, isValidEmail(email: email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }

        guard let user = try await User.query(on: req.db).filter(\.$email == email).first(),
              user.passwordHash != nil else {
            throw Abort(.notFound, reason: "Такая почта не зарегистрирована")
        }

        try await emailCodeService.sendReset(user: user, req: req)
        return .noContent
    }

    private func resetPassword(req: Request) async throws -> AuthDTO {
        let data = try req.content.decode(ResetPasswordRequest.self)
        let email = normalizedEmail(email: data.email)
        try validatePassword(password: data.password)

        let code = data.code.trimmingCharacters(in: .whitespacesAndNewlines)
        let result: Result<AuthDTO, Abort> = try await req.db.transaction { db in
            guard let user = try await lockedUser(email: email, db: db), user.passwordHash != nil else {
                throw Abort(.badRequest, reason: "Код недействителен. Запросите новый")
            }
            let userID = try user.requireID()
            do {
                try await emailCodeService.verifyReset(code: code, userID: userID, db: db)
            } catch let rejection as Abort {
                return .failure(rejection)
            }

            user.passwordHash = try await req.password.async.hash(data.password)
            user.emailConfirmedAt = user.emailConfirmedAt ?? Date()
            try await user.save(on: db)
            try await Token.query(on: db).filter(\.$user.$id == userID).delete()
            try await PasswordReset.query(on: db).filter(\.$user.$id == userID).delete()
            return .success(try await issueToken(user: user, database: db))
        }
        return try result.get()
    }

    private func lockedUser(email: String, db: any Database) async throws -> User? {
        try await db.sql().raw("SELECT * FROM users WHERE email = \(bind: email) FOR UPDATE")
            .first(decodingFluent: User.self)
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

    private func emailExists(_ email: String, database: any Database) async throws -> Bool {
        try await User.query(on: database).filter(\.$email == email).first() != nil
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
