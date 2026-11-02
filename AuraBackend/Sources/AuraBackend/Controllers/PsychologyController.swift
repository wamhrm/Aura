//
//  PsychologyController.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import FluentPostgresDriver
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
        let usage = try await reserveTest(for: user, on: req.db)

        do {
            let response = try await psychologyService.makePersonalityTest(user: user, testTitles: testTitles, req: req)

            try await saveTestResult(user: user,
                                     kind: .personality,
                                     selectedTests: response.selectedTests,
                                     result: response,
                                     on: req.db)

            return response
        } catch {
            try? await usage.delete(on: req.db)
            throw error
        }
    }

    private func makeCompatibilityTest(_ req: Request) async throws -> CompatibilityResultDTO {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CompatibilityTestRequest.self)
        let usage = try await reserveTest(for: user, on: req.db)

        do {
            let response = try await psychologyService.makeCompatibilityTest(user: user, request: request, req: req)

            try await saveTestResult(user: user,
                                     kind: .compatibility,
                                     selectedTests: response.selectedTests,
                                     result: response,
                                     on: req.db)

            return response
        } catch {
            try? await usage.delete(on: req.db)
            throw error
        }
    }

    // Takes an attempt before OpenAI is called, so parallel requests can't pass the limit together
    private func reserveTest(for user: User, on database: any Database) async throws -> TestUsage {
        let userID = try user.requireID()

        return try await database.transaction { transaction in
            try await transaction.sql().raw("SELECT id FROM users WHERE id = \(bind: userID) FOR UPDATE").run()

            try await TestUsage.query(on: transaction)
                .filter(\.$user.$id == userID)
                .filter(\.$createdAt < Date().addingTimeInterval(-dailyTestLimitWindow))
                .delete()

            let testsInLastDay = try await TestUsage.query(on: transaction)
                .filter(\.$user.$id == userID)
                .count()

            guard testsInLastDay < dailyTestLimit else {
                throw Abort(.tooManyRequests, reason: "Достигнут лимит тестов за сутки. Попробуйте позже")
            }

            let usage = TestUsage(userID: userID)
            try await usage.save(on: transaction)
            return usage
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

        let entry = History(userID: try user.requireID(),
                            kind: kind,
                            selectedTests: selectedTests,
                            result: resultJSON)

        try await entry.save(on: database)
    }
}
