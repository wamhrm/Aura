//
//  DailyContentController.swift
//  AuraBackend
//
//  Created by ddorsat on 26.05.2026.
//

import Vapor

struct DailyContentController: RouteCollection {
    private let dailyContentService = DailyContentService()

    func boot(routes: any RoutesBuilder) throws {
        let daily = routes.grouped("daily")
            .grouped(UserAuthMiddleware())

        daily.get("insight", use: fetchDailyInsight)
        daily.get("tip", use: fetchDailyTip)
    }

    private func fetchDailyInsight(_ req: Request) async throws -> DailyContentDTO {
        let user = try req.auth.require(User.self)
        return try await dailyContentService.fetchDailyInsight(for: user, req: req, on: req.db)
    }

    private func fetchDailyTip(_ req: Request) async throws -> DailyContentDTO {
        let user = try req.auth.require(User.self)
        return try await dailyContentService.fetchDailyTip(for: user, req: req, on: req.db)
    }
}
