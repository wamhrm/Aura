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
            .grouped(EmailConfirmedMiddleware())

        history.post("personality", use: makePersonalityTest)
        history.post("compatibility", use: makeCompatibilityTest)
    }

    private func makePersonalityTest(_ req: Request) async throws -> PersonalityResultDTO {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let testKeys = try req.content.decode([String].self)
        let requestID = try idempotencyKey(of: req)

        return try await SingleFlight.shared.run(key: "test:\(userID):\(requestID)") {
            if let entry = try await findEntry(kind: .personality, requestID: requestID, userID: userID, on: req.db) {
                return try HistoryDTOMapper.decodePersonalityResult(from: entry.result)
            }

            let usage = try await reserveTest(for: user, on: req.db)

            do {
                let response = try await psychologyService.makePersonalityTest(user: user, testKeys: testKeys, req: req)
                let entry = History(userID: userID,
                                    requestID: requestID,
                                    kind: .personality,
                                    selectedTests: response.selectedTests,
                                    title: response.archetypeTitle,
                                    subtitle: response.archetypeSubtitle,
                                    zodiacSign: response.zodiacSign,
                                    result: try encodedResult(response))

                try await entry.save(on: req.db)

                return response
            } catch {
                try? await usage.delete(on: req.db)
                throw error
            }
        }
    }

    private func makeCompatibilityTest(_ req: Request) async throws -> CompatibilityResultDTO {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let request = try req.content.decode(CompatibilityTestRequest.self)
        let requestID = try idempotencyKey(of: req)

        return try await SingleFlight.shared.run(key: "test:\(userID):\(requestID)") {
            if let entry = try await findEntry(kind: .compatibility, requestID: requestID, userID: userID, on: req.db) {
                return try HistoryDTOMapper.decodeCompatibilityResult(from: entry.result)
            }

            let usage = try await reserveTest(for: user, on: req.db)

            do {
                let response = try await psychologyService.makeCompatibilityTest(user: user, request: request, req: req)
                let entry = History(userID: userID,
                                    requestID: requestID,
                                    kind: .compatibility,
                                    selectedTests: response.selectedTests,
                                    title: response.title,
                                    subtitle: response.subtitle,
                                    zodiacSign: response.userZodiacSign,
                                    compatibilityScore: response.compatibilityScore,
                                    partnerName: response.partnerName,
                                    partnerZodiacSign: response.partnerZodiacSign,
                                    result: try encodedResult(response))

                try await entry.save(on: req.db)

                return response
            } catch {
                try? await usage.delete(on: req.db)
                throw error
            }
        }
    }

    // The app repeats a test with the same key when the first answer was lost on the way
    private func idempotencyKey(of req: Request) throws -> UUID {
        guard let key = req.headers.first(name: "Idempotency-Key").flatMap(UUID.init(uuidString:)) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор запроса")
        }

        return key
    }

    private func findEntry(kind: TestKind,
                           requestID: UUID,
                           userID: UUID,
                           on database: any Database) async throws -> History? {
        try await History.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$requestID == requestID)
            .filter(\.$kind == kind)
            .first()
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

    private func encodedResult<T: Encodable>(_ result: T) throws -> String {
        let resultData = try JSONEncoder().encode(result)

        guard let resultJSON = String(data: resultData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Не удалось сохранить результат теста")
        }

        return resultJSON
    }
}
