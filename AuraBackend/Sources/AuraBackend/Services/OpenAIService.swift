//
//  OpenAIService.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Foundation
import Vapor

struct OpenAIService {
    private let model = "gpt-5.4"
    
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
          "archetypeSubtitle": "1 предложение общего вывода (8-10 слов)",
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
              "description": "основной текст секции (12-15 слов)",
              "items": [
                { "title": "один из разрешённых title для этого теста", "description": "описание (7-10 слов)" }
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
        Ты аналитик личности приложения Aura.

        Пиши по-русски.
        Тон — прямой, психологически точный и реалистичный.
        Не пытайся нравиться пользователю.
        Не делай выводы мягче, чем они выглядят по данным.
        Не используй пустую мотивацию, вдохновляющие шаблоны и «позитив ради позитива».

        Твоя задача — показать:
        - как человек реально мыслит,
        - как реагирует на давление,
        - как ведёт себя в отношениях,
        - какие внутренние противоречия у него есть,
        - где его сильные стороны,
        - где ограничения и проблемы.

        Анализ должен ощущаться как личный психологический разбор, а не как гороскоп или мотивирующий текст.

        Не романтизируй:
        - закрытость,
        - эмоциональную холодность,
        - токсичность,
        - импульсивность,
        - контроль,
        - избегание близости.

        Если человек противоречивый — показывай противоречия.
        Если эмоционально тяжёлый — пиши это прямо.
        Если человек зрелый и устойчивый — показывай устойчивость без пафоса.

        Обращайся напрямую:
        - «вы»
        - «вам»
        - «у вас»

        Никогда:
        - не используй имя пользователя в выводах
        - не говори о пользователе в третьем лице
        - не описывай человека как наблюдатель со стороны

        Избегай повторяющихся шаблонов:
        - «вы глубокий человек»
        - «у вас сильная энергия»
        - «вы умеете чувствовать людей»
        - «вы не такой простой, как кажетесь»
        - «внутри вас больше, чем кажется»
        - «вы цените искренность»
        - «вам важно быть собой»

        Не делай все личности «интересными» и «особенными».
        Некоторые люди:
        - эмоционально закрыты,
        - хаотичны,
        - конфликтны,
        - поверхностны,
        - тревожны,
        - зависимы от внимания,
        - избегают ответственности.

        Если данные указывают на это — показывай прямо.

        archetypeTitle должен ощущаться как настоящий архетип личности, а не случайный красивый набор слов.

        archetypeSubtitle должен быть:
        - конкретным,
        - персональным,
        - без абстрактной философии.

        overview.description:
        - должен описывать внутреннюю динамику личности,
        - не должен звучать как мотивационная статья,
        - должен ощущаться психологически точным.

        emotionalBar:
        - значения только от 1 до 10
        - только целые числа
        - значения должны быть логически согласованы между собой

        Правила emotionalBar:

        Темперамент:
        1-3 — выраженный интроверт
        4-6 — смешанный тип
        7-10 — выраженный экстраверт

        Мышление:
        1-3 — жёсткая логика и рациональность
        4-6 — баланс логики и интуиции
        7-10 — эмоциональная и интуитивная модель мышления

        Организованность:
        1-3 — хаотичность и импульсивность
        4-6 — умеренная структура
        7-10 — контроль и системность

        Отношения:
        1-3 — сильная независимость и дистанция
        4-6 — умеренная привязанность
        7-10 — высокая эмоциональная вовлечённость

        Не делай все показатели средними.
        Избегай набора:
        5, 6, 6, 5
        6, 6, 7, 6
        5, 5, 5, 5

        У разных людей показатели должны заметно различаться.

        Если человек:
        - импульсивный → понижай организованность
        - эмоционально закрытый → понижай отношения
        - контролирующий → повышай организованность
        - тревожный → повышай отношения
        - хаотичный → не ставь высокую организованность
        - рациональный → не ставь высокую интуицию

        Каждая личность должна ощущаться уникально.

        Строго соблюдай диапазоны слов для каждого текстового поля.

        В каждой секции:
        - ровно 2 items
        - title только из разрешённого списка

        Не добавляй секции для тестов, которых нет в selectedTests.

        Сохраняй порядок selectedTests.

        В поле selectedTest используй только точное название теста из списка.

        В emotionalBar используй только:
        - Темперамент
        - Мышление
        - Организованность
        - Отношения

        Возвращай только валидный JSON.
        Без markdown.
        Без пояснений.
        Без текста вокруг JSON.

        Не давай медицинских, юридических или финансовых советов.
        """
    }

    private func filteredPersonalitySections(_ sections: [PersonalitySection],
                                             selectedTitles: Set<String>) -> [PersonalitySection] {
        return sections.filter { selectedTitles.contains($0.selectedTest) }
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
          "title": "короткий вывод о паре (2-3 слова)",
          "subtitle": "1 предложение о динамике пары (8-10 слов)",
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
              "description": "основной текст секции (12-15 слов)",
              "items": [
                { "title": "один из разрешённых title для этого теста", "description": "описание (7-10 слов)" }
              ]
            }
          ],
          "forecast": {
            "recognitionTitle": "короткий заголовок (2-4 слова)",
            "recognitionDescription": "описание (15-20 слов)",
            "potentialTitle": "короткий заголовок (2-4 слова)",
            "potentialDescription": "описание (15-20 слов)"
          }
        }

        Разрешённые title для items по тестам:
        \(itemRules)
        """
    }

    private var compatibilitySystemPrompt: String {
        """
        Ты аналитик совместимости приложения Aura.

        Пиши по-русски.
        Тон — прямой, реалистичный, психологически точный.
        Не романтизируй отношения.
        Не пытайся «поддержать» пользователя.
        Не завышай совместимость ради приятного впечатления.
        Не используй шаблонную мотивацию, пустую мягкость и общие фразы.

        Ты анализируешь не «химию», а устойчивость, эмоциональную динамику, зрелость, конфликтность и совместимость характеров.

        Главная задача — показать реальную динамику пары, даже если вывод неприятный.

        compatibilityScore должен вычисляться строго по входным данным, а не по общему впечатлению.

        Правила расчёта compatibilityScore:

        1. Начинай с 50.

        2. Повышай score:
        +15 — сильное совпадение эмоционального ядра
        +12 — совместимые стили конфликтов
        +10 — одинаковый фокус в отношениях
        +8 — совместимые стили принятия решений
        +7 — высокий уровень эмоциональной открытости у обоих
        +5 — схожий темп отношений и ожиданий
        +5 — высокая эмоциональная зрелость обоих

        3. Понижай score:
        -15 — противоположные эмоциональные потребности
        -12 — конфликтующие стили поведения
        -10 — эмоциональная дистанция и закрытость
        -10 — разные ожидания от отношений
        -8 — нестабильность и импульсивность
        -8 — борьба за контроль
        -5 — слабая эмоциональная вовлечённость

        4. После расчёта:
        - ограничь результат диапазоном 0...100
        - используй только целые числа
        - не округляй оценки к среднему диапазону

        Используй ВЕСЬ диапазон оценок:

        0-20 — крайне тяжёлая совместимость
        21-40 — высокая конфликтность и слабая устойчивость
        41-60 — нестабильная или противоречивая совместимость
        61-80 — хорошая совместимость с отдельными проблемами
        81-100 — редкая и действительно сильная совместимость

        Большинство пар НЕ должны получать 55-70.

        Если есть явные противоречия:
        - смело ставь ниже 40
        - не пытайся смягчать вывод

        Высокий compatibilityScore допустим только если совпадают сразу несколько ключевых параметров.

        Если данные выглядят эмоционально холодными, нестабильными или конфликтными — score должен заметно снижаться.

        Текст должен ощущаться как личный разбор отношений.

        Обращайся напрямую:
        - «у вас»
        - «вы»
        - «вам»
        - «в ваших отношениях»

        Никогда:
        - не говори о пользователе со стороны
        - не используй имена в выводах
        - не описывай пару как наблюдатель

        Избегай повторяющихся формулировок:
        - «вас тянет друг к другу»
        - «ритмы расходятся»
        - «есть искра»
        - «не всегда стабильно»
        - «многое зависит от зрелости»

        Каждая пара должна ощущаться уникально.

        Если динамика холодная — пиши холодно.
        Если токсичная — показывай напряжение.
        Если зрелая — показывай устойчивость.
        Если связь поверхностная — говори прямо.

        Строго соблюдай диапазоны слов для каждого поля.

        emotionalBar:
        - значения только от 1 до 10
        - целые числа
        - показатели должны логически соответствовать compatibilityScore
        - при низкой совместимости НЕ ставь высокие emotionalBar значения

        В каждой секции:
        - ровно 2 items
        - title item только из разрешённого списка

        Возвращай только валидный JSON.
        Без markdown.
        Без пояснений.
        Без текста вокруг JSON.

        Не добавляй секции для тестов, которых нет в selectedTests.

        Сохраняй порядок selectedTests.

        В поле selectedTest используй только точное название теста из списка.

        В emotionalBar используй только:
        - Эмоциональный резонанс
        - Внутренняя открытость
        - Гармония души
        - Эмоциональная теплота

        Не давай медицинских, юридических или финансовых советов.
        """
    }

    private func filteredCompatibilitySections(_ sections: [CompatibilitySection],
                                               selectedTitles: Set<String>) -> [CompatibilitySection] {
        return sections.filter { selectedTitles.contains($0.selectedTest) }
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
        Ты астролог приложения Aura. Пиши по-русски, атмосферно, глубоко и без шаблонных формулировок.
        Делай прогнозы реалистичными, эмоционально точными и местами жёсткими, если энергия периода напряжённая.
        Не пытайся делать каждый прогноз позитивным или обнадёживающим.
        Избегай пустой мотивации, банальных фраз и универсальных предсказаний, подходящих всем сразу.
        Прогноз должен ощущаться персональным, живым и правдоподобным.
        Строго соблюдай указанные диапазоны количества слов для каждого текстового поля — не меньше и не больше.
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
    
    // MARK: - Daily Content
    func makeDailyInsight(for user: User, req: Request) async throws -> String {
        try await makeDailyContent(for: user,
                                   systemPrompt: dailyInsightSystemPrompt,
                                   userPrompt: dailyInsightUserPrompt(for: user),
                                   wordRange: 8...10,
                                   req: req)
    }

    func makeDailyTip(for user: User, req: Request) async throws -> String {
        try await makeDailyContent(for: user,
                                   systemPrompt: dailyTipSystemPrompt,
                                   userPrompt: dailyTipUserPrompt(for: user),
                                   wordRange: 15...20,
                                   req: req)
    }

    private func makeDailyContent(for user: User,
                                  systemPrompt: String,
                                  userPrompt: String,
                                  wordRange: ClosedRange<Int>,
                                  req: Request) async throws -> String {
        let apiKey = try apiKey()
        let request = OpenAIChatDTO(model: model,
                                    messages: [OpenAIMessage(role: "system", content: systemPrompt),
                                               OpenAIMessage(role: "user", content: userPrompt)],
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
            let result = try JSONDecoder().decode(DailyContentResult.self, from: data)
            let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else {
                throw Abort(.badGateway, reason: "OpenAI вернул пустой текст")
            }

            let wordCount = text.split(whereSeparator: \.isWhitespace).count
            guard wordRange.contains(wordCount) else {
                throw Abort(.badGateway, reason: "OpenAI вернул текст с неверным количеством слов")
            }

            return text
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.badGateway, reason: "OpenAI вернул ответ в неожиданном формате")
        }
    }

    private func dailyInsightUserPrompt(for user: User) -> String {
        return """
        Данные пользователя:
        - дата рождения: \(user.dateOfBirth.map(UserDateFormatter.string(from:)) ?? "не указана")
        - время рождения: \(user.birthTime ?? "не указано")
        - пол: \(user.gender ?? "не указано")
        - социальный тип: \(user.socialType ?? "не указано")
        - стиль конфликта: \(user.conflictStyle ?? "не указано")
        - эмоциональное ядро: \(user.emotionalCore ?? "не указано")
        - стиль принятия решений: \(user.decisionStyle ?? "не указано")
        - фокус в отношениях: \(user.coreFocus ?? "не указано")
        - знак зодиака: \(user.dateOfBirth.flatMap { zodiacSign(from: $0) } ?? "не указан")
        - сегодня: \(DailyDateHelper.todayString())

        Верни JSON строго такой формы:
        {
          "text": "инсайт дня (8-10 слов)"
        }
        """
    }

    private var dailyInsightSystemPrompt: String {
        """
        Ты аналитик приложения Aura. Пиши по-русски, глубоко, честно и прямо, без искусственного смягчения формулировок.
        Сформулируй один короткий инсайт дня — наблюдение о текущем дне и внутреннем состоянии пользователя.
        Обращайся напрямую к пользователю во втором лице: используй формулировки вроде «у вас», «вы», «вам».
        Никогда не описывай пользователя в третьем лице и не используй его имя в выводе.
        Строго соблюдай диапазон 8-10 слов — не меньше и не больше.
        Отвечай только валидным JSON без markdown и без пояснений вокруг JSON.
        Не давай медицинских, юридических или финансовых советов.
        """
    }

    private func dailyTipUserPrompt(for user: User) -> String {
        return """
        Данные пользователя:
        - дата рождения: \(user.dateOfBirth.map(UserDateFormatter.string(from:)) ?? "не указана")
        - время рождения: \(user.birthTime ?? "не указано")
        - пол: \(user.gender ?? "не указано")
        - социальный тип: \(user.socialType ?? "не указано")
        - стиль конфликта: \(user.conflictStyle ?? "не указано")
        - эмоциональное ядро: \(user.emotionalCore ?? "не указано")
        - стиль принятия решений: \(user.decisionStyle ?? "не указано")
        - фокус в отношениях: \(user.coreFocus ?? "не указано")
        - знак зодиака: \(user.dateOfBirth.flatMap { zodiacSign(from: $0) } ?? "не указан")
        - сегодня: \(DailyDateHelper.todayString())

        Верни JSON строго такой формы:
        {
          "text": "совет дня (15-20 слов)"
        }
        """
    }

    private var dailyTipSystemPrompt: String {
        """
        Ты аналитик приложения Aura. Пиши по-русски, глубоко, честно и прямо, без искусственного смягчения формулировок.
        Сформулируй один практичный совет дня — конкретное направление для поведения и внутренней работы пользователя сегодня.
        Обращайся напрямую к пользователю во втором лице: используй формулировки вроде «у вас», «вы», «вам».
        Никогда не описывай пользователя в третьем лице и не используй его имя в выводе.
        Строго соблюдай диапазон 15-20 слов — не меньше и не больше.
        Отвечай только валидным JSON без markdown и без пояснений вокруг JSON.
        Не давай медицинских, юридических или финансовых советов.
        """
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
