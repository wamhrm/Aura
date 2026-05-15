import Fluent
import Vapor

struct UserAuthMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let tokenString = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Токен не найден")
        }

        guard let tokenModel = try await Token.query(on: req.db)
            .filter(\.$value == tokenString)
            .with(\.$user)
            .first()
        else { throw Abort(.unauthorized, reason: "Неверный токен") }

        req.auth.login(tokenModel.user)

        return try await next.respond(to: req)
    }
}
