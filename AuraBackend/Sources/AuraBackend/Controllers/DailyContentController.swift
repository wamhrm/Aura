//
//  DailyContentController.swift
//  AuraBackend
//
//  Created by wamhrm on 26.05.2026.
//

import Vapor

struct DailyContentController: RouteCollection {
    private let dailyContentService = DailyContentService()

    func boot(routes: any RoutesBuilder) throws {
        let daily = routes.grouped("daily")
            .grouped(UserAuthMiddleware())
            .grouped(AIConsentMiddleware())

        daily.get("insight", use: fetchDailyInsight)
        daily.get("tip", use: fetchDailyTip)
    }

    private func fetchDailyInsight(req: Request) async throws -> DailyContentDTO {
        let user = try req.auth.require(User.self)
        return try await dailyContentService.fetchDailyInsight(user: user, req: req, database: req.db)
    }

    private func fetchDailyTip(req: Request) async throws -> DailyContentDTO {
        let user = try req.auth.require(User.self)
        return try await dailyContentService.fetchDailyTip(user: user, req: req, database: req.db)
    }
}
