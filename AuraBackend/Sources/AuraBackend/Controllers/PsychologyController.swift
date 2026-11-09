//
//  PsychologyController.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct PsychologyController: RouteCollection {
    private let psychologyService = PsychologyService()

    func boot(routes: any RoutesBuilder) throws {
        let history = routes.grouped("history")
            .grouped(UserAuthMiddleware())
            .grouped(AIConsentMiddleware())
            .grouped(EmailConfirmedMiddleware())

        history.post("personality", use: makePersonalityTest)
        history.post("compatibility", use: makeCompatibilityTest)
    }

    private func makePersonalityTest(req: Request) async throws -> PersonalityResultDTO {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let testKeys = try req.content.decode([String].self)
        let requestID = try idempotencyKey(req: req)

        if let entry = try await findEntry(kind: .personality, requestID: requestID, userID: userID, database: req.db) {
            return try HistoryDTOMapper.decodePersonalityResult(resultJSON: entry.result)
        }

        let response = try await psychologyService.makePersonalityTest(user: user, testKeys: testKeys, req: req)
        let entry = History(userID: userID,
                            requestID: requestID,
                            kind: .personality,
                            selectedTests: response.selectedTests,
                            title: response.archetypeTitle,
                            subtitle: response.archetypeSubtitle,
                            zodiacSign: response.zodiacSign,
                            result: try encodedResult(result: response))

        try await entry.save(on: req.db)
        return response
    }

    private func makeCompatibilityTest(req: Request) async throws -> CompatibilityResultDTO {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let request = try req.content.decode(CompatibilityTestRequest.self)
        let requestID = try idempotencyKey(req: req)

        if let entry = try await findEntry(kind: .compatibility, requestID: requestID, userID: userID, database: req.db) {
            return try HistoryDTOMapper.decodeCompatibilityResult(resultJSON: entry.result)
        }

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
                            result: try encodedResult(result: response))

        try await entry.save(on: req.db)
        return response
    }

    private func idempotencyKey(req: Request) throws -> UUID {
        guard let key = req.headers.first(name: "Idempotency-Key").flatMap(UUID.init(uuidString:)) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор запроса")
        }

        return key
    }

    private func findEntry(kind: TestKind,
                           requestID: UUID,
                           userID: UUID,
                           database: any Database) async throws -> History? {
        guard let entry = try await History.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$requestID == requestID)
            .first() else { return nil }

        guard entry.kind == kind else {
            throw Abort(.conflict, reason: "Этот идентификатор запроса уже использован для другого вида теста")
        }

        return entry
    }

    private func encodedResult<T: Encodable>(result: T) throws -> String {
        let resultData = try JSONEncoder().encode(result)
        return String(decoding: resultData, as: UTF8.self)
    }
}
