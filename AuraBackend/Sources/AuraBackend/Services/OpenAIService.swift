//
//  OpenAIService.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Foundation
import Vapor

struct OpenAIService {
    private let model = "gpt-5.4-mini"
    
    private func apiKey() throws -> String {
        if let key = Environment.get("OPENAI_KEY"), !key.isEmpty {
            return key
        }

        throw Abort(.serviceUnavailable, reason: "OPENAI_KEY не задан")
    }

    // MARK: - Personality
    func makePersonalityTest(for user: User,
                             selectedTests: [PersonalityTests],
                             req: Request) async throws -> PersonalityResultDTO {
        let apiKey = try apiKey()
        let request = OpenAIChatDTO(model: model,
                                    messages: [OpenAIMessage(role: "system", content: personalitySystemPrompt),
                                               OpenAIMessage(role: "user",
                                                             content: personalityUserPrompt(for: user,
                                                                                            selectedTests: selectedTests))],
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
            let analysis = try JSONDecoder().decode(PersonalityTestContent.self, from: data)
            let selectedTitles = Set(selectedTests.map(\.title))

            return PersonalityResultDTO(name: user.name,
                                        zodiacSign: zodiacSign(from: user.dateOfBirth) ?? "",
                                        selectedTests: selectedTests.map(\.title),
                                        archetypeTitle: analysis.archetypeTitle,
                                        archetypeSubtitle: analysis.archetypeSubtitle,
                                        overview: analysis.overview,
                                        emotionalBar: analysis.emotionalBar,
                                        sections: filteredPersonalitySections(analysis.sections,
                                                                              selectedTitles: selectedTitles))
        } catch {
            throw Abort(.badGateway, reason: "OpenAI вернул ответ в неожиданном формате")
        }
    }

    private func personalityUserPrompt(for user: User, selectedTests: [PersonalityTests]) -> String {
        let selectedTestLines = selectedTests
            .map { "- " + $0.title }
            .joined(separator: "\n")

        let itemRules = selectedTests
            .map { test in
                let titles = PersonalityItems.allowed(for: test)
                    .map { "\"" + $0 + "\"" }
                    .joined(separator: ", ")
                return "- " + test.title + ": ровно 2 пункта, title только из [" + titles + "]"
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

    private var personalitySystemPrompt: String {
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

    private func filteredPersonalitySections(_ sections: [PersonalitySection],
                                             selectedTitles: Set<String>) -> [PersonalitySection] {
        sections.filter { selectedTitles.contains($0.selectedTest) }
    }

    // MARK: - Compatibility
    func makeCompatibilityTest(for user: User,
                               partner: CompatibilityTestRequest,
                               selectedTests: [CompatibilityTests],
                               req: Request) async throws -> CompatibilityResultDTO {
        let apiKey = try apiKey()
        let request = OpenAIChatDTO(model: model,
                                    messages: [OpenAIMessage(role: "system", content: compatibilitySystemPrompt),
                                               OpenAIMessage(role: "user", content: compatibilityUserPrompt(
                                                                                              for: user,
                                                                                              partner: partner,
                                                                                              selectedTests: selectedTests))],
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
            let analysis = try JSONDecoder().decode(CompatibilityTestContent.self, from: data)
            let selectedTitles = Set(selectedTests.map(\.title))
            let partnerDate = compatibilityPartnerDateOfBirth(from: partner)

            return CompatibilityResultDTO(userName: user.name,
                                          userZodiacSign: zodiacSign(from: user.dateOfBirth) ?? "",
                                          partnerName: partner.partnerName,
                                          partnerZodiacSign: zodiacSign(from: partnerDate) ?? "",
                                          compatibilityScore: min(max(analysis.compatibilityScore, 0), 100),
                                          selectedTests: selectedTests.map(\.title),
                                          title: analysis.title,
                                          subtitle: analysis.subtitle,
                                          overview: analysis.overview,
                                          emotionalBar: analysis.emotionalBar,
                                          sections: filteredCompatibilitySections(analysis.sections,
                                                                                  selectedTitles: selectedTitles),
                                          forecast: analysis.forecast)
        } catch {
            throw Abort(.badGateway, reason: "OpenAI вернул ответ в неожиданном формате")
        }
    }

    private func compatibilityUserPrompt(for user: User,
                                         partner: CompatibilityTestRequest,
                                         selectedTests: [CompatibilityTests]) -> String {
        let selectedTestLines = selectedTests
            .map { "- " + $0.title }
            .joined(separator: "\n")

        let itemRules = selectedTests
            .map { test in
                let titles = CompatibilityItems.allowed(for: test)
                    .map { "\"" + $0 + "\"" }
                    .joined(separator: ", ")
                return "- " + test.title + ": ровно 2 пункта, title только из [" + titles + "]"
            }
            .joined(separator: "\n")

        let partnerBirthDate = partner.exactDateOfBirth
            ? (partner.partnerDateOfBirth ?? "не указана")
            : (partner.partnerAge.map { $0 + " лет" } ?? "не указан")

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

        Данные партнёра:
        - имя: \(partner.partnerName)
        - дата рождения или возраст: \(partnerBirthDate)
        - время рождения: \(partner.partnerBirthTime ?? "не указано")
        - пол: \(partner.partnerGender)

        Выбранные тесты:
        \(selectedTestLines)

        Верни JSON строго такой формы:
        {
          "title": "короткий вывод о паре (3-5 слов)",
          "subtitle": "1 предложение о динамике пары",
          "compatibilityScore": целое число от 0 до 100,
          "overview": {
            "title": "Основная динамика",
            "description": "общий вывод о паре (20-25 слов)"
          },
          "emotionalBar": [
            { "title": "Эмоциональный резонанс", "value": от 1 до 10 },
            { "title": "Внутренняя открытость", "value": от 1 до 10 },
            { "title": "Гармония души", "value": от 1 до 10 },
            { "title": "Эмоциональная теплота", "value": от 1 до 10 }
          ],
          "sections": [
            {
              "selectedTest": "точное название одного из тестов из списка выбранных",
              "description": "основной текст секции (8-10 слов)",
              "items": [
                { "title": "один из разрешённых title для этого теста", "description": "описание (5-10 слов)" }
              ]
            }
          ],
          "forecast": {
            "recognitionTitle": "короткий заголовок (2-4 слова)",
            "recognitionDescription": "описание (10-15 слов)",
            "potentialTitle": "короткий заголовок (2-4 слова)",
            "potentialDescription": "описание (10-15 слов)"
          }
        }

        Разрешённые title для items по тестам:
        \(itemRules)
        """
    }

    private var compatibilitySystemPrompt: String {
        """
        Ты аналитик совместимости приложения Aura. Пиши по-русски, мягко и без категоричных диагнозов.
        Отвечай только валидным JSON без markdown и без пояснений вокруг JSON.
        Не добавляй секции для тестов, которых нет в списке выбранных тестов.
        Если выбрана часть тестов, верни только выбранные секции в том порядке, в котором они пришли.
        В поле selectedTest используй только точное название теста из списка выбранных.
        В emotionalBar используй только title: Эмоциональный резонанс, Внутренняя открытость, Гармония души, Эмоциональная теплота.
        Значения emotionalBar.value и compatibilityScore должны быть целыми числами.
        В каждой секции ровно 2 items. title каждого item должен быть строго из разрешённого списка для этого теста.
        Не давай медицинских, юридических или финансовых советов.
        """
    }

    private func filteredCompatibilitySections(_ sections: [CompatibilitySection],
                                               selectedTitles: Set<String>) -> [CompatibilitySection] {
        sections.filter { selectedTitles.contains($0.selectedTest) }
    }

    private func compatibilityPartnerDateOfBirth(from partner: CompatibilityTestRequest) -> Date? {
        guard partner.exactDateOfBirth,
              let dateString = partner.partnerDateOfBirth else {
            return nil
        }

        return UserDateFormatter.date(from: dateString)
    }

    // MARK: - Horoscope
    func makeHoroscopeTest(for sign: HoroscopeSign, req: Request) async throws -> HoroscopeContentResult {
        let apiKey = try apiKey()
        let request = OpenAIChatDTO(model: model,
                                    messages: [OpenAIMessage(role: "system", content: horoscopeSystemPrompt),
                                               OpenAIMessage(role: "user", content: horoscopeUserPrompt(for: sign))],
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
            return try JSONDecoder().decode(HoroscopeContentResult.self, from: data)
        } catch {
            throw Abort(.badGateway, reason: "OpenAI вернул ответ в неожиданном формате")
        }
    }

    private func horoscopeUserPrompt(for sign: HoroscopeSign) -> String {
        let period = horoscopePeriod()

        return """
        Знак зодиака: \(sign.rawValue)
        Текущий период прогноза: \(period.start) — \(period.end)

        Верни JSON строго такой формы:
        {
          "description": "краткий гороскоп на период (35-50 слов)",
          "items": [
            { "title": "Любовь", "description": "прогноз по любви (20-30 слов)" },
            { "title": "Здоровье", "description": "прогноз по здоровью и самочувствию (20-30 слов)" },
            { "title": "Работа", "description": "прогноз по работе (20-30 слов)" }
          ]
        }

        В items ровно 3 элемента. title каждого item должен быть строго: Любовь, Здоровье, Работа.
        """
    }

    private var horoscopeSystemPrompt: String {
        """
        Ты астролог приложения Aura. Пиши по-русски, мягко и без категоричных предсказаний.
        Отвечай только валидным JSON без markdown и без пояснений вокруг JSON.
        В items ровно 3 элемента с title: Любовь, Здоровье, Работа.
        Не давай медицинских, юридических или финансовых советов.
        """
    }
    
    func horoscopePeriod() -> (start: String, end: String) {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let startDate = calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? now
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "d MMM"
        return (formatter.string(from: startDate), formatter.string(from: endDate))
    }

    private func zodiacSign(from date: Date?) -> String? {
        guard let date else { return nil }

        let components = Calendar(identifier: .gregorian).dateComponents([.day, .month], from: date)
        guard let day = components.day, let month = components.month else { return nil }

        switch (month, day) {
            case (1, 20...31),  (2, 1...18):
                return "♒️"
            case (2, 19...29),  (3, 1...20):
                return "♓️"
            case (3, 21...31),  (4, 1...19):
                return "♈️"
            case (4, 20...30),  (5, 1...20):
                return "♉️"
            case (5, 21...31),  (6, 1...20):
                return "♊️"
            case (6, 21...30),  (7, 1...22):
                return "♋️"
            case (7, 23...31),  (8, 1...22):
                return "♌️"
            case (8, 23...31),  (9, 1...22):
                return "♍️"
            case (9, 23...30),  (10, 1...22):
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
