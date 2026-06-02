//
//  HoroscopeController.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Vapor

struct HoroscopeController: RouteCollection {
    private let horoscopeService = HoroscopeService()

    func boot(routes: any RoutesBuilder) throws {
        let horoscope = routes.grouped("horoscope")
            .grouped(UserAuthMiddleware())

        horoscope.get("current", use: fetchCurrentHoroscope)
    }

    private func fetchCurrentHoroscope(_ req: Request) async throws -> HoroscopeDTO {
        let user = try req.auth.require(User.self)
        return try await horoscopeService.fetchCurrentHoroscope(for: user, req: req, on: req.db)
    }
}
