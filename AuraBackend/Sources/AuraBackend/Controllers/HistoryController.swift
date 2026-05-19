import Fluent
import Vapor

struct HistoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let history = routes.grouped("history")
            .grouped(UserAuthMiddleware())

        history.get(use: historyItemIndex)
        history.get(":historyID", use: getHistoryItemByID)
        history.post("personality", use: makePersonalityTest)
    }

    private func historyItemIndex(_ req: Request) async throws -> [HistoryItemDTO] {
        let userID = try req.auth.require(User.self).requireID()

        let entries = try await History.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        return try entries.map { try HistoryDTOMapper.listItem(from: $0) }
    }

    private func getHistoryItemByID(_ req: Request) async throws -> HistoryItemDetailsDTO {
        let userID = try req.auth.require(User.self).requireID()

        guard let historyID = req.parameters.get("historyID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор записи")
        }

        guard let entry = try await History.query(on: req.db)
            .filter(\.$id == historyID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound, reason: "Запись не найдена")
        }

        return try HistoryDTOMapper.detail(from: entry)
    }

    private func makePersonalityTest(_ req: Request) async throws -> PersonalityResultDTO {
        let user = try req.auth.require(User.self)
        let testTitles = try req.content.decode([String].self)

        guard let selectedTests = PersonalityTests.from(titles: testTitles) else {
            throw Abort(.badRequest, reason: "Неизвестный тест в списке выбранных")
        }

        let uniqueSelectedTests = uniqueTests(from: selectedTests)

        guard uniqueSelectedTests.count >= 2 else {
            throw Abort(.badRequest, reason: "Выберите минимум 2 теста")
        }

        guard hasCompletedProfileInfo(user) else {
            throw Abort(.badRequest, reason: "Заполните профиль перед прохождением теста")
        }

        let response = try await OpenAIService().generate(for: user,
                                                          selectedTests: uniqueSelectedTests,
                                                          req: req)

        let resultData = try JSONEncoder().encode(response)
        guard let result = String(data: resultData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Не удалось сохранить результат теста")
        }

        let entry = History(userID: try user.requireID(),
                            kind: .personality,
                            selectedTests: response.selectedTests,
                            result: result)
        try await entry.save(on: req.db)

        return response
    }

    private func uniqueTests(from tests: [PersonalityTests]) -> [PersonalityTests] {
        var seen = Set<PersonalityTests>()

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
