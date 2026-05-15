import Fluent
import Vapor

struct PersonalityController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let personality = routes.grouped("personality")
            .grouped(UserAuthMiddleware())

        personality.post("generate", use: generate)
    }

    private func generate(_ req: Request) async throws -> PersonalityAnalysisResponse {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(PersonalityAnalysisRequest.self)
        let selectedTests = uniqueTests(from: request.selectedTests)

        guard selectedTests.count >= 2 else {
            throw Abort(.badRequest, reason: "Выберите минимум 2 теста")
        }

        guard hasCompletedProfileInfo(user) else {
            throw Abort(.badRequest, reason: "Заполните профиль перед прохождением теста")
        }

        return try await OpenAIPersonalityService().generate(for: user, selectedTests: selectedTests, req: req)
    }

    private func uniqueTests(from tests: [PersonalityTestID]) -> [PersonalityTestID] {
        var seen = Set<PersonalityTestID>()

        return tests.filter { test in
            seen.insert(test).inserted
        }
    }

    private func hasCompletedProfileInfo(_ user: User) -> Bool {
        user.dateOfBirth != nil &&
        user.gender != nil &&
        user.socialType != nil &&
        user.conflictStyle != nil &&
        user.emotionalCore != nil &&
        user.decisionStyle != nil &&
        user.coreFocus != nil
    }
}
