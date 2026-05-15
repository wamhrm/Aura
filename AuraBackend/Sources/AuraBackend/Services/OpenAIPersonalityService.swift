import Foundation
import Vapor

struct OpenAIPersonalityService {
    private let model = "gpt-5.4-mini"

    func generate(for user: User, selectedTests: [PersonalityTestID], req: Request) async throws -> PersonalityAnalysisResponse {
        let apiKey = try apiKey()
        let request = OpenAIChatRequest(model: model,
                                        messages: [OpenAIMessage(role: "system", content: systemPrompt),
                      OpenAIMessage(role: "user",
                                    content: userPrompt(for: user, selectedTests: selectedTests))],
                                    responseFormat: OpenAIResponseFormat(type: "json_object"))

        let response = try await req.client.post("https://api.openai.com/v1/chat/completions") { clientRequest in
            clientRequest.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
            clientRequest.headers.contentType = .json
            try clientRequest.content.encode(request)
        }

        guard response.status == .ok else {
            let error = try? response.content.decode(OpenAIErrorResponse.self)
            throw Abort(.badGateway, reason: error?.error.message ?? "OpenAI вернул ошибку")
        }

        let chatResponse = try response.content.decode(OpenAIChatResponse.self)

        guard let content = chatResponse.choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw Abort(.badGateway, reason: "OpenAI вернул пустой ответ")
        }

        do {
            let analysis = try JSONDecoder().decode(PersonalityAnalysisContent.self, from: data)
            let selectedTitles = Set(selectedTests.map(\.title))

            return PersonalityAnalysisResponse(name: user.name,
                                               zodiacSign: zodiacSign(from: user.dateOfBirth) ?? "",
                                               selectedTests: selectedTests.map(\.title),
                                               archetypeTitle: analysis.archetypeTitle,
                                               archetypeSubtitle: analysis.archetypeSubtitle,
                                               overview: analysis.overview,
                                               emotionalBar: analysis.emotionalBar,
                                               sections: filteredSections(analysis.sections,
                                                                          selectedTitles: selectedTitles))
        } catch {
            throw Abort(.badGateway, reason: "OpenAI вернул ответ в неожиданном формате")
        }
    }

    private func apiKey() throws -> String {
        if let key = Environment.get("OPENAI_KEY"), !key.isEmpty {
            return key
        }

        if let key = Environment.get("OPENAI_API_KEY"), !key.isEmpty {
            return key
        }

        throw Abort(.serviceUnavailable, reason: "OPENAI_KEY не задан")
    }

    private func userPrompt(for user: User, selectedTests: [PersonalityTestID]) -> String {
        let selectedTestLines = selectedTests
            .map { "- \($0.title)" }
            .joined(separator: "\n")

        let itemRules = selectedTests
            .map { test in
                let titles = PersonalityItemTitles.allowed(for: test).map { "\"\($0)\"" }.joined(separator: ", ")
                return "- \(unsafeRaw: test.title): ровно 2 пункта, title только из [\(unsafeRaw: titles)]"
            }
            .joined(separator: "\n")

        return """
        Данные пользователя:
        - имя: \(user.name)
        - дата рождения: \(user.dateOfBirth.map(UserDateFormatter.string(from:)) ?? "не указана")
        - время рождения: \(user.birthTime ?? "не указано")
        - пол: \(user.gender ?? "не указано")
        - социальный тип: \(user.socialType ?? "не указано")
        - стиль конфликта: \(user.conflictStyle ?? "не указано")
        - эмоциональное ядро: \(user.emotionalCore ?? "не указано")
        - стиль принятия решений: \(user.decisionStyle ?? "не указано")
        - фокус в отношениях: \(user.coreFocus ?? "не указано")

        Выбранные тесты:
        \(selectedTestLines)

        Верни JSON строго такой формы:
        {
          "archetypeTitle": "короткое название архетипа (1-2 слова)",
          "archetypeSubtitle": "1 предложение общего вывода",
          "overview": {
            "title": "Основная характеристика",
            "description": "общий персональный вывод (20-25 слов)"
          },
          "emotionalBar": [
            { "title": "Темперамент", "value": дай значение от 1 до 10 (1 это максимальный интроверт, 10 это максимальный экстраверт) },
            { "title": "Мышление", "value": дай значение от 1 до 10 (1 это максимальная лоигка, 10 это максимальная интуиция) },
            { "title": "Организованность", "value": дай значение от 1 до 10 (1 это максимальный хаос, 10 это максимальный контроль) },
            { "title": "Отношения", "value": дай значение от 1 до 10 (1 это максимальная независимость, 10 это максимальная привязанность) }
          ],
          "sections": [
            {
              "selectedTest": "точное название одного из тестов из списка выбранных",
              "description": "основной текст секции (8-10 слов)",
              "items": [
                { "title": "один из разрешённых title для этого теста", "description": "описание (5-10 слов)" }
              ]
            }
          ]
        }

        Разрешённые title для items по тестам:
        \(itemRules)
        """
    }

    private var systemPrompt: String {
        """
        Ты аналитик приложения Aura. Пиши по-русски, мягко, глубоко и без категоричных диагнозов.
        Отвечай только валидным JSON без markdown и без пояснений вокруг JSON.
        Не добавляй секции для тестов, которых нет в списке выбранных тестов.
        Если выбрана часть тестов, верни только выбранные секции в том порядке, в котором они пришли.
        В поле selectedTest используй только точное название теста из списка выбранных.
        В emotionalBar используй только title: Темперамент, Мышление, Организованность, Отношения.
        Значения emotionalBar.value должны быть целыми числами от 1 до 10.
        В каждой секции ровно 2 items. title каждого item должен быть строго из разрешённого списка для этого теста.
        Не давай медицинских, юридических или финансовых советов.
        """
    }

    private func filteredSections(_ sections: [PersonalityAnalysisResultSection],
                                  selectedTitles: Set<String>) -> [PersonalityAnalysisResultSection] {
        sections.filter { selectedTitles.contains($0.selectedTest) }
    }

    private func zodiacSign(from date: Date?) -> String? {
        guard let date else { return nil }

        let components = Calendar(identifier: .gregorian).dateComponents([.day, .month], from: date)
        guard let day = components.day, let month = components.month else { return nil }

        switch (month, day) {
            case (1, 20...31), (2, 1...18):
                return "♒️"
            case (2, 19...29), (3, 1...20):
                return "♓️"
            case (3, 21...31), (4, 1...19):
                return "♈️"
            case (4, 20...30), (5, 1...20):
                return "♉️"
            case (5, 21...31), (6, 1...20):
                return "♊️"
            case (6, 21...30), (7, 1...22):
                return "♋️"
            case (7, 23...31), (8, 1...22):
                return "♌️"
            case (8, 23...31), (9, 1...22):
                return "♍️"
            case (9, 23...30), (10, 1...22):
                return "♎️"
            case (10, 23...31), (11, 1...21):
                return "♏️"
            case (11, 22...30), (12, 1...21):
                return "♐️"
            case (12, 22...31), (1, 1...19):
                return "♑️"
            default:
                return nil
        }
    }
}
