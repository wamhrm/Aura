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

    func boot(routes: any RoutesBuilder) throws {
        let history = routes.grouped("history")
            .grouped(UserAuthMiddleware())

        history.post("personality", use: makePersonalityTest)
        history.post("compatibility", use: makeCompatibilityTest)
    }

    private func makePersonalityTest(_ req: Request) async throws -> PersonalityResultDTO {
        let user = try req.auth.require(User.self)
        let testTitles = try req.content.decode([String].self)
        let response = try await psychologyService.makePersonalityTest(user: user, testTitles: testTitles, req: req)

        try await saveHistory(user: user,
                              kind: .personality,
                              selectedTests: response.selectedTests,
                              result: response,
                              on: req.db)

        return response
    }

    private func makeCompatibilityTest(_ req: Request) async throws -> CompatibilityResultDTO {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CompatibilityTestRequest.self)
        let response = try await psychologyService.makeCompatibilityTest(user: user, request: request, req: req)

        try await saveHistory(user: user,
                              kind: .compatibility,
                              selectedTests: response.selectedTests,
                              result: response,
                              on: req.db)

        return response
    }

    private func saveHistory<T: Encodable>(user: User,
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
