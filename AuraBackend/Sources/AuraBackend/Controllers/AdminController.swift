import Fluent
import Vapor

struct AdminController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get("users", use: getUsers)
        routes.delete("users", use: deleteAllUsers)
        routes.delete("history", use: deleteAllHistory)
    }

    private func getUsers(_ req: Request) async throws -> [UserDTO] {
        let users = try await User.query(on: req.db).all()
        return try users.map { try $0.toDTO() }
    }

    private func deleteAllUsers(_ req: Request) async throws -> HTTPStatus {
        try await User.query(on: req.db).delete()
        return .noContent
    }

    private func deleteAllHistory(_ req: Request) async throws -> HTTPStatus {
        try await History.query(on: req.db).delete()
        return .noContent
    }
}
