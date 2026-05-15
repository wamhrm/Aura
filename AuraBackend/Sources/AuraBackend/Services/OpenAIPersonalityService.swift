import Foundation
import Vapor

struct OpenAIPersonalityService {
    private let model = "gpt-5.4-mini"

    func generate(for user: User,
                  selectedTests: [PersonalityTestID],
                  req: Request) async throws -> PersonalityAnalysisResponse {
        let apiKey = try apiKey()
        let request = OpenAIChatRequest(
            model: model,
            messages: [OpenAIMessage(role: "system", content: systemPrompt),
                       OpenAIMessage(role: "user", content: userPrompt(for: user, selectedTests: selectedTests))],
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

            return PersonalityAnalysisResponse(userName: user.name,
                                               zodiacSign: zodiacSign(from: user.dateOfBirth),
                                               selectedTests: selectedTests,
                                               archetypeTitle: analysis.archetypeTitle,
                                               archetypeSubtitle: analysis.archetypeSubtitle,
                                               overview: analysis.overview,
                                               scales: analysis.scales,
                                               sections: filteredSections(analysis.sections, selectedTests: selectedTests))
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
            .map { "- \($0.rawValue): \($0.title)" }
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
          "archetypeTitle": "короткое название архетипа",
          "archetypeSubtitle": "1-2 предложения общего вывода",
          "overview": {
            "title": "Основная характеристика",
            "body": "общий персональный вывод"
          },
          "scales": [
            { "title": "Темперамент", "value": 1 },
            { "title": "Мышление", "value": 1 },
            { "title": "Организация", "value": 1 },
            { "title": "Отношения", "value": 1 }
          ],
          "sections": [
            {
              "testID": "один из выбранных id",
              "title": "название секции",
              "body": "основной текст секции",
              "items": [
                { "title": "короткий подпункт", "description": "описание" }
              ]
            }
          ]
        }
        """
    }

    private var systemPrompt: String {
        """
        Ты аналитик приложения Aura. Пиши по-русски, мягко, глубоко и без категоричных диагнозов.
        Отвечай только валидным JSON без markdown и без пояснений вокруг JSON.
        Не добавляй секции для тестов, которых нет в списке выбранных тестов.
        Если выбраны все шесть тестов, верни все шесть секций в порядке: astrology, behavioralPatterns, decisionMaking, attachmentStyle, idealPartner, loveLanguage.
        Если выбрана часть тестов, верни только выбранные секции в том порядке, в котором они пришли.
        В поле testID используй только исходный id выбранного теста.
        Значения scales.value должны быть целыми числами от 1 до 10.
        Не давай медицинских, юридических или финансовых советов.
        """
    }

    private func filteredSections(_ sections: [PersonalityResultSection],
                                  selectedTests: [PersonalityTestID]) -> [PersonalityResultSection] {
        let selected = Set(selectedTests)
        return sections.filter { selected.contains($0.testID) }
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
