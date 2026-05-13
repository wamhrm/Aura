import Foundation

protocol PersonalityAnalysisServiceProtocol: AnyObject {
    func generate(selectedTests: [TestTypes]) async throws -> PersonalityAnalysisResult
}

final class PersonalityAnalysisService: PersonalityAnalysisServiceProtocol {
    private let tokenStorage: any TokenStorageProtocol

    init(tokenStorage: (any TokenStorageProtocol)? = nil) {
        self.tokenStorage = tokenStorage ?? KeychainTokenStorage()
    }

    func generate(selectedTests: [TestTypes]) async throws -> PersonalityAnalysisResult {
        guard let token = try tokenStorage.readToken() else {
            throw PersonalityAnalysisError.missingToken
        }

        let request = PersonalityAnalysisRequest(selectedTests: selectedTests.map(\.apiID))

        return try await NetworkHelper.request(endpoint: "/personality/generate",
                                               method: .post,
                                               body: request,
                                               token: token)
    }
}

final class MockPersonalityAnalysisService: PersonalityAnalysisServiceProtocol {
    func generate(selectedTests: [TestTypes]) async throws -> PersonalityAnalysisResult {
        PersonalityAnalysisResult(userName: "Дмитрий",
                                  zodiacSign: "♑️",
                                  selectedTests: selectedTests.map(\.apiID),
                                  archetypeTitle: "Спокойный стратег",
                                  archetypeSubtitle: "Вы редко действуете импульсивно и почти всегда замечаете то, что другие упускают.",
                                  overview: PersonalityTextSection(title: "Основная характеристика",
                                                                   body: "Вы производите впечатление спокойного человека, но внутри постоянно анализируете людей, ситуации и собственные реакции."),
                                  scales: [
                                    PersonalityScale(title: "Темперамент", value: 5),
                                    PersonalityScale(title: "Мышление", value: 7),
                                    PersonalityScale(title: "Организация", value: 3),
                                    PersonalityScale(title: "Отношения", value: 6)
                                  ],
                                  sections: selectedTests.map { test in
                                    PersonalityResultSection(testID: test.apiID,
                                                             title: test.title,
                                                             body: test.deepDescription,
                                                             items: [
                                                                PersonalityResultItem(title: "Ключевой вывод",
                                                                                      description: test.description)
                                                             ])
                                  })
    }
}

struct PersonalityAnalysisRequest: Encodable {
    let selectedTests: [String]
}

struct PersonalityAnalysisResult: Decodable {
    let userName: String
    let zodiacSign: String?
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityTextSection
    let scales: [PersonalityScale]
    let sections: [PersonalityResultSection]
}

struct PersonalityTextSection: Decodable {
    let title: String
    let body: String
}

struct PersonalityScale: Decodable {
    let title: String
    let value: Int
}

struct PersonalityResultSection: Decodable {
    let testID: String
    let title: String
    let body: String
    let items: [PersonalityResultItem]
}

struct PersonalityResultItem: Decodable {
    let title: String
    let description: String
}

enum PersonalityAnalysisError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        switch self {
            case .missingToken:
                return "Войдите в аккаунт, чтобы пройти тест"
        }
    }
}
