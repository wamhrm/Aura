//
//  DailyContentController.swift
//  AuraServer
//
//  Created by ddorsat on 26.05.2026.
//

import Vapor

struct DailyContentController: RouteCollection {
    private let dailyContentService = DailyContentService()

    func boot(routes: any RoutesBuilder) throws {
        let daily = routes.grouped("daily")
            .grouped(UserAuthMiddleware())

        daily.get("insight", use: getDailyInsight)
        daily.get("tip", use: getDailyTip)
    }

    private func getDailyInsight(_ req: Request) async throws -> DailyInsightDTO {
        let user = try req.auth.require(User.self)
        return try await dailyContentService.getOrGenerateDailyInsight(for: user, req: req, on: req.db)
    }

    private func getDailyTip(_ req: Request) async throws -> DailyTipDTO {
        let user = try req.auth.require(User.self)
        return try await dailyContentService.getOrGenerateDailyTip(for: user, req: req, on: req.db)
    }
}
