import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        auth.post("createAccount", use: createAccount)
        auth.post("signIn", use: signIn)
    }

    private func createAccount(_ req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(CreateAccountRequest.self)
        let name = data.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = normalizedEmail(data.email)

        guard name.count >= 2 else {
            throw Abort(.badRequest, reason: "Имя должно содержать минимум 2 символа")
        }
        guard isValidEmail(email) else {
            throw Abort(.badRequest, reason: "Укажите корректный e-mail")
        }
        guard data.password.count >= 6 else {
            throw Abort(.badRequest, reason: "Пароль должен быть не короче 6 символов")
        }

        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first()

        if existingUser != nil { throw Abort(.conflict, reason: "Пользователь уже зарегистрирован") }

        let digest = try Bcrypt.hash(data.password)
        let user = User(name: name, email: email, passwordHash: digest)

        try await user.save(on: req.db)

        return .created
    }

    private func signIn(_ req: Request) async throws -> AuthDTO {
        let signInData = try req.content.decode(SignInRequest.self)
        let email = normalizedEmail(signInData.email)

        guard let user = try await User.query(on: req.db)
            .filter(\User.$email == email)
            .first()
        else { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        let isPasswordCorrect = try Bcrypt.verify(signInData.password, created: user.passwordHash)

        if !isPasswordCorrect { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }

        let tokenValue = [UInt8].random(count: 16).base64
        let token = Token(value: tokenValue, userID: try user.requireID())
        try await token.save(on: req.db)

        return AuthDTO(token: tokenValue, user: try user.toDTO())
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
