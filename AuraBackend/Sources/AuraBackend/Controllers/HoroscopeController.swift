//
//  HoroscopeController.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct HoroscopeController: RouteCollection {
    private let horoscopeService = HoroscopeService()

    func boot(routes: any RoutesBuilder) throws {
        let horoscope = routes.grouped("horoscope")
            .grouped(UserAuthMiddleware())

        horoscope.get("current", use: getCurrentHoroscope)
        horoscope.get(":horoscopeID", use: getHoroscope)
        horoscope.delete(":horoscopeID", use: deleteHoroscope)
    }

    private func getCurrentHoroscope(_ req: Request) async throws -> HoroscopeDTO {
        let user = try req.auth.require(User.self)
        return try await horoscopeService.currentHoroscopeTest(for: user, on: req.db)
    }

    private func getHoroscope(_ req: Request) async throws -> HoroscopeDTO {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        guard let horoscopeID = req.parameters.get("horoscopeID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор гороскопа")
        }

        guard let entry = try await Horoscope.query(on: req.db)
            .filter(\.$id == horoscopeID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound, reason: "Гороскоп не найден")
        }

        return try HoroscopeDTOMapper.map(entry)
    }

    private func deleteHoroscope(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        guard let horoscopeID = req.parameters.get("horoscopeID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор гороскопа")
        }

        guard let entry = try await Horoscope.query(on: req.db)
            .filter(\.$id == horoscopeID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound, reason: "Гороскоп не найден")
        }

        try await entry.delete(on: req.db)
        return .noContent
    }
}
