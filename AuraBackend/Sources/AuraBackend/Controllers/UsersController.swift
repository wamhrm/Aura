import Fluent
import Vapor

struct UsersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: listAll)
        users.delete(use: deleteAll)
    }

    @Sendable
    func listAll(req: Request) async throws -> [UserResponse] {
        let records = try await User.query(on: req.db).all()
        return try records.map { try $0.toResponse() }
    }

    @Sendable
    func deleteAll(req: Request) async throws -> HTTPStatus {
        try await User.query(on: req.db).delete()
        return .noContent
    }
}
