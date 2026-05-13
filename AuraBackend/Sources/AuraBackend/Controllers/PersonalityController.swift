import Fluent
import JWT
import Vapor

struct PersonalityController: RouteCollection {
    private let minSelectedTests = 2

    func boot(routes: any RoutesBuilder) throws {
        let personality = routes.grouped("personality")
        personality.post("generate", use: generate)
    }

    @Sendable
    func generate(req: Request) async throws -> PersonalityAnalysisResponse {
        let payload = try await req.jwt.verify(as: AccessTokenPayload.self)
        let request = try req.content.decode(PersonalityAnalysisRequest.self)
        let selectedTests = uniqueTests(from: request.selectedTests)

        guard selectedTests.count >= minSelectedTests else {
            throw Abort(.badRequest, reason: "Выберите минимум 2 теста")
        }

        guard let userID = UUID(uuidString: payload.subject.value),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "Недействительный токен")
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
