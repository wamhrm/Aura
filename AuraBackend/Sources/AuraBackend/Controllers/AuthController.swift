//
//  AuthController.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct AuthController: RouteCollection {
    private let appleAuthService = AppleAuthService()
    private let passwordResetService = PasswordResetService()

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        let limited = auth.grouped(RateLimitMiddleware(limit: 10, window: 60))
        limited.post("createAccount", use: createAccount)
        limited.post("signIn", use: signIn)
        limited.post("apple", use: signInWithApple)
        limited.post("password", "forgot", use: requestPasswordReset)
        limited.post("password", "reset", use: resetPassword)

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
        try validatePassword(data.password)

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
            .first(),
              let passwordHash = user.passwordHash
        else { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        let isPasswordCorrect = try await req.password.async.verify(signInData.password, created: passwordHash)

        if !isPasswordCorrect { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        return try await issueToken(for: user, on: req)
    }

    private func requestPasswordReset(_ req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(ForgotPasswordRequest.self)
        let email = normalizedEmail(data.email)

        guard email.count <= InputLimits.maxEmailLength, isValidEmail(email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }

        if let user = try await User.query(on: req.db).filter(\.$email == email).first(), user.passwordHash != nil {
            try await passwordResetService.sendCode(to: user, req: req)
        }

        return .noContent
    }

    private func resetPassword(_ req: Request) async throws -> AuthDTO {
        let data = try req.content.decode(ResetPasswordRequest.self)
        let email = normalizedEmail(data.email)
        try validatePassword(data.password)

        guard let user = try await User.query(on: req.db).filter(\.$email == email).first(),
              user.passwordHash != nil
        else { throw Abort(.badRequest, reason: "Код недействителен. Запросите новый") }

        try await passwordResetService.verifyCode(data.code.trimmingCharacters(in: .whitespacesAndNewlines),
                                                  for: user,
                                                  req: req)

        let userID = try user.requireID()
        user.passwordHash = try await req.password.async.hash(data.password)

        try await req.db.transaction { database in
            try await user.save(on: database)
            try await Token.query(on: database).filter(\.$user.$id == userID).delete()
            try await PasswordReset.query(on: database).filter(\.$user.$id == userID).delete()
        }

        return try await issueToken(for: user, on: req)
    }

    private func signInWithApple(_ req: Request) async throws -> AuthDTO {
        let data = try req.content.decode(AppleSignInRequest.self)
        let identityToken = try await appleAuthService.verifyIdentityToken(data.identityToken, nonce: data.nonce, req: req)
        let appleUserID = identityToken.subject.value

        let user: User
        if let existingUser = try await User.query(on: req.db).filter(\.$appleUserID == appleUserID).first() {
            user = existingUser
        } else {
            user = try await createAppleUser(appleUserID: appleUserID, name: data.name, on: req)
        }

        if user.appleRefreshToken == nil, let authorizationCode = data.authorizationCode {
            user.appleRefreshToken = await appleAuthService.refreshToken(for: authorizationCode, req: req)
            try await user.save(on: req.db)
        }

        return try await issueToken(for: user, on: req)
    }

    private func createAppleUser(appleUserID: String, name: String?, on req: Request) async throws -> User {
        let trimmedName = String((name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(InputLimits.maxNameLength))
        let user = User(name: trimmedName.count >= InputLimits.minNameLength ? trimmedName : "Пользователь",
                        appleUserID: appleUserID)

        do {
            try await user.save(on: req.db)
            return user
        } catch {
            guard (error as? any DatabaseError)?.isConstraintFailure == true,
                  let existingUser = try await User.query(on: req.db).filter(\.$appleUserID == appleUserID).first()
            else { throw error }

            return existingUser
        }
    }

    private func issueToken(for user: User, on req: Request) async throws -> AuthDTO {
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

        if let appleRefreshToken = user.appleRefreshToken {
            await appleAuthService.revoke(refreshToken: appleRefreshToken, req: req)
        } else if user.appleUserID != nil {
            req.logger.warning("Apple token not revoked: no refresh token stored")
        }

        try await user.delete(on: req.db)
        return .noContent
    }

    private func validatePassword(_ password: String) throws {
        guard password.count >= InputLimits.minPasswordLength else {
            throw Abort(.badRequest, reason: "Пароль должен быть не короче 6 символов")
        }
        guard password.utf8.count <= InputLimits.maxPasswordBytes else {
            throw Abort(.badRequest, reason: "Пароль слишком длинный")
        }
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
