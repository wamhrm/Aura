//
//  CompatibilityPrompts.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Foundation

enum CompatibilityPrompts {
    static func schema(for selectedTests: [CompatibilityTests]) -> JSONSchema {
        let itemKeys = selectedTests.flatMap(CompatibilityItems.allowed(for:)).map(\.rawValue)

        return .object([("title", .string),
                        ("subtitle", .string),
                        ("compatibilityScore", .integer),
                        ("overview", .titledText),
                        ("emotionalBar", .array(.object([("key", .stringEnum(CompatibilityEmotionalBar.keys)),
                                                         ("value", .integer)]))),
                        ("sections", .array(.object([("selectedTest", .stringEnum(selectedTests.map(\.rawValue))),
                                                     ("description", .string),
                                                     ("items", .array(.object([("key", .stringEnum(itemKeys)),
                                                                               ("description", .string)])))]))),
                        ("forecast", .object([("recognitionTitle", .string),
                                              ("recognitionDescription", .string),
                                              ("potentialTitle", .string),
                                              ("potentialDescription", .string)]))])
    }

    static func user(for user: User,
                     partner: CompatibilityTestRequest,
                     selectedTests: [CompatibilityTests]) -> String {
        let selectedTestLines = selectedTests
            .map { "- " + $0.rawValue + " (" + $0.title + ")" }
            .joined(separator: "\n")

        let itemRules = selectedTests
            .map { test in
                let keys = CompatibilityItems.allowed(for: test)
                    .map { "\"" + $0.rawValue + "\" (" + $0.title + ")" }
                    .joined(separator: ", ")
                return "- " + test.rawValue + ": ровно 2 пункта, key только из [" + keys + "]"
            }
            .joined(separator: "\n")

        let partnerBirthDate = partner.exactDateOfBirth
            ? (partner.partnerDateOfBirth ?? "не указана")
            : (partner.partnerAge.map { $0 + " лет" } ?? "не указан")

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

        Данные партнёра:
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
            { "key": "emotionalResonance", "value": от 1 до 10 },
            { "key": "innerOpenness", "value": от 1 до 10 },
            { "key": "soulAlignment", "value": от 1 до 10 },
            { "key": "emotionalWarmth", "value": от 1 до 10 }
          ],
          "sections": [
            {
              "selectedTest": "ключ одного из тестов из списка выбранных",
              "description": "основной текст секции (12-15 слов)",
              "items": [
                { "key": "один из разрешённых key для этого теста", "description": "описание (7-10 слов)" }
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

        Разрешённые key для items по тестам:
        \(itemRules)
        """
    }

    static var system: String {
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
        - key item только из разрешённого списка

        Возвращай только валидный JSON.
        Без markdown.
        Без пояснений.
        Без текста вокруг JSON.

        Не добавляй секции для тестов, которых нет в selectedTests.

        Сохраняй порядок selectedTests.

        В поле selectedTest используй только ключ теста из списка.

        В emotionalBar используй только:
        - emotionalResonance (Эмоциональный резонанс)
        - innerOpenness (Внутренняя открытость)
        - soulAlignment (Гармония души)
        - emotionalWarmth (Эмоциональная теплота)

        Не давай медицинских, юридических или финансовых советов.
        """
    }
}
