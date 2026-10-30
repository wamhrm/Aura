//
//  HistoryController.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct HistoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let history = routes.grouped("history")
            .grouped(UserAuthMiddleware())

        history.get(use: fetchHistory)
        history.get(":historyID", use: fetchHistoryDetails)
        history.delete(":historyID", use: deleteHistory)
    }

    private func fetchHistory(_ req: Request) async throws -> [HistoryItemDTO] {
        let userID = try req.auth.require(User.self).requireID()

        let entries = try await History.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        return entries.compactMap { entry in
            do {
                return try HistoryDTOMapper.getHistoryItem(from: entry)
            } catch {
                req.logger.warning("Skipping corrupted history entry \(entry.id?.uuidString ?? "unknown"): \(error)")
                return nil
            }
        }
    }

    private func fetchHistoryDetails(_ req: Request) async throws -> HistoryItemDTO {
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

        do {
            return try HistoryDTOMapper.getHistoryItemDetails(from: entry)
        } catch {
            req.logger.error("Failed to decode history entry \(historyID): \(error)")
            throw Abort(.internalServerError, reason: "Не удалось открыть запись истории")
        }
    }

    private func deleteHistory(_ req: Request) async throws -> HTTPStatus {
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
