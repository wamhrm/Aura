import Fluent
import Vapor

struct HistoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let history = routes.grouped("history")
            .grouped(UserAuthMiddleware())

        history.get(use: getHistory)
        history.get(":historyID", use: getHistoryItemDetails)
        history.delete(":historyID", use: deleteHistoryItem)
    }

    private func getHistory(_ req: Request) async throws -> [HistoryItemDTO] {
        let userID = try req.auth.require(User.self).requireID()

        let entries = try await History.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        return try entries.map { try HistoryDTOMapper.listItem(from: $0) }
    }

    private func getHistoryItemDetails(_ req: Request) async throws -> HistoryItemDTO {
        let userID = try req.auth.require(User.self).requireID()

        guard let historyID = req.parameters.get("historyID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор записи")
        }

        guard let entry = try await History.query(on: req.db)
            .filter(\.$id == historyID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound, reason: "Запись не найдена")
        }

        return try HistoryDTOMapper.detail(from: entry)
    }

    private func deleteHistoryItem(_ req: Request) async throws -> HTTPStatus {
        let userID = try req.auth.require(User.self).requireID()

        guard let historyID = req.parameters.get("historyID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор записи")
        }

        guard let entry = try await History.query(on: req.db)
            .filter(\.$id == historyID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound, reason: "Запись не найдена")
        }

        try await entry.delete(on: req.db)
        return .noContent
    }
}
