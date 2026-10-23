//
//  PsychologyController.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct PsychologyController: RouteCollection {
    private let psychologyService = PsychologyService()
    private let dailyTestLimit = 10
    private let dailyTestLimitWindow: TimeInterval = 24 * 60 * 60

    func boot(routes: any RoutesBuilder) throws {
        let history = routes.grouped("history")
            .grouped(UserAuthMiddleware())
            .grouped(AIConsentMiddleware())

        history.post("personality", use: makePersonalityTest)
        history.post("compatibility", use: makeCompatibilityTest)
    }

    private func makePersonalityTest(_ req: Request) async throws -> PersonalityResultDTO {
        let user = try req.auth.require(User.self)
        let testTitles = try req.content.decode([String].self)
        try await ensureDailyTestLimit(for: user, on: req.db)
        let response = try await psychologyService.makePersonalityTest(user: user, testTitles: testTitles, req: req)

        try await saveTestResult(user: user,
                                 kind: .personality,
                                 selectedTests: response.selectedTests,
                                 result: response,
                                 on: req.db)

        return response
    }

    private func makeCompatibilityTest(_ req: Request) async throws -> CompatibilityResultDTO {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CompatibilityTestRequest.self)
        try await ensureDailyTestLimit(for: user, on: req.db)
        let response = try await psychologyService.makeCompatibilityTest(user: user, request: request, req: req)

        try await saveTestResult(user: user,
                                 kind: .compatibility,
                                 selectedTests: response.selectedTests,
                                 result: response,
                                 on: req.db)

        return response
    }

    private func ensureDailyTestLimit(for user: User, on database: any Database) async throws {
        let userID = try user.requireID()

        try await TestUsage.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt < Date().addingTimeInterval(-dailyTestLimitWindow))
            .delete()

        let testsInLastDay = try await TestUsage.query(on: database)
            .filter(\.$user.$id == userID)
            .count()

        guard testsInLastDay < dailyTestLimit else {
            throw Abort(.tooManyRequests, reason: "Достигнут лимит тестов за сутки. Попробуйте позже")
        }
    }

    private func saveTestResult<T: Encodable>(user: User,
                                              kind: TestKind,
                                              selectedTests: [String],
                                              result: T,
                                              on database: any Database) async throws {
        let resultData = try JSONEncoder().encode(result)

        guard let resultJSON = String(data: resultData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Не удалось сохранить результат теста")
        }

        let userID = try user.requireID()
        let entry = History(userID: userID,
                            kind: kind,
                            selectedTests: selectedTests,
                            result: resultJSON)
        let usage = TestUsage(userID: userID)

        try await database.transaction { transaction in
            try await entry.save(on: transaction)
            try await usage.save(on: transaction)
        }
    }
}
