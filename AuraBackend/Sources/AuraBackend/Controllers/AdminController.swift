//
//  AdminController.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct AdminController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get("users", use: getUsers)
        routes.get("horoscopes", use: getHoroscopes)
        routes.delete("users", use: deleteAllUsers)
        routes.delete("history", use: deleteAllHistory)
        routes.delete("horoscopes", use: deleteAllHoroscopes)
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

    private func getHoroscopes(_ req: Request) async throws -> [HoroscopeDTO] {
        let entries = try await Horoscope.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()

        return try entries.map { try HoroscopeDTOMapper.map($0) }
    }

    private func deleteAllHoroscopes(_ req: Request) async throws -> HTTPStatus {
        try await Horoscope.query(on: req.db).delete()
        return .noContent
    }
}
