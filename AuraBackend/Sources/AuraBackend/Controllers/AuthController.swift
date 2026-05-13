import Fluent
import JWT
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("createAccount", use: createAccount)
        auth.post("signIn", use: signIn)
        auth.get("autoSignIn", use: autoSignIn)
        auth.patch("profileInfo", use: updateProfileInfo)
    }

    @Sendable
    func createAccount(req: Request) async throws -> AuthResponse {
        let payload = try req.content.decode(RegisterUserRequest.self)
        let name = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = normalizedEmail(payload.email)

        guard !name.isEmpty else {
            throw Abort(.badRequest, reason: "Введите имя")
        }
        guard isValidEmail(email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }
        guard payload.password.count >= 6 else {
            throw Abort(.badRequest, reason: "Пароль должен быть не короче 6 символов")
        }

        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first()

        guard existingUser == nil else {
            throw Abort(.conflict, reason: "Пользователь уже зарегистрирован")
        }

        let user = try User(name: name,
                            email: email,
                            passwordHash: Bcrypt.hash(payload.password))

        try await user.save(on: req.db)
        
        return try await authResponse(for: user, req: req)
    }

    @Sendable
    func signIn(req: Request) async throws -> AuthResponse {
        let payload = try req.content.decode(LoginUserRequest.self)
        let email = normalizedEmail(payload.email)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first(),
            try Bcrypt.verify(payload.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Неправильная почта или пароль")
        }

        return try await authResponse(for: user, req: req)
    }

    @Sendable
    func autoSignIn(req: Request) async throws -> UserResponse {
        let payload = try await req.jwt.verify(as: AccessTokenPayload.self)

        guard let userID = UUID(uuidString: payload.subject.value),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "Недействительный токен")
        }

        return try user.toResponse()
    }

    @Sendable
    func updateProfileInfo(req: Request) async throws -> UserResponse {
        let payload = try await req.jwt.verify(as: AccessTokenPayload.self)
        let profileInfo = try req.content.decode(UpdateProfileInfoRequest.self)

        guard let dateOfBirth = UserDateFormatter.date(from: profileInfo.dateOfBirth) else {
            throw Abort(.badRequest, reason: "Укажите дату рождения в формате ДД.ММ.ГГГГ")
        }

        guard let userID = UUID(uuidString: payload.subject.value),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "Недействительный токен")
        }

        user.dateOfBirth = dateOfBirth
        user.birthTime = emptyStringToNil(profileInfo.birthTime)
        user.gender = profileInfo.gender
        user.socialType = profileInfo.socialType
        user.conflictStyle = profileInfo.conflictStyle
        user.emotionalCore = profileInfo.emotionalCore
        user.decisionStyle = profileInfo.decisionStyle
        user.coreFocus = profileInfo.coreFocus

        try await user.save(on: req.db)
        return try user.toResponse()
    }

    private func authResponse(for user: User, req: Request) async throws -> AuthResponse {
        let token = try await req.jwt.sign(AccessTokenPayload(
            subject: .init(value: user.requireID().uuidString),
            expiration: .init(value: Date().addingTimeInterval(60 * 60 * 24 * 30)),
            email: user.email))

        return try AuthResponse(token: token, user: user.toResponse())
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

    private func emptyStringToNil(_ string: String?) -> String? {
        guard let string else { return nil }
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedString.isEmpty ? nil : trimmedString
    }
}
