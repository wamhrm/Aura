//
//  ContentPrompts.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Foundation

enum ContentPrompts {
    static var horoscopeSchema: JSONSchema {
        .object([("description", .string),
                 ("items", .array(.object([("key", .stringEnum(HoroscopeDTOMapper.sphereKeys)),
                                           ("description", .string)])))])
    }

    static var dailySchema: JSONSchema {
        .object([("text", .string)])
    }

    static func horoscopeUser(for sign: HoroscopeSign, period: (start: String, end: String)) -> String {
        """
        Знак зодиака: \(sign.title)
        Текущий период прогноза: \(period.start) — \(period.end)

        Верни JSON строго такой формы:
        {
          "description": "гороскоп на период (60-80 слов)",
          "items": [
            { "key": "love", "description": "прогноз по любви (20-30 слов)" },
            { "key": "health", "description": "прогноз по здоровью и самочувствию (20-30 слов)" },
            { "key": "work", "description": "прогноз по работе (20-30 слов)" }
          ]
        }

        В items ровно 3 элемента. key каждого item должен быть строго: love, health, work.
        """
    }

    static var horoscopeSystem: String {
        """
        Ты астролог приложения Aura. Пиши по-русски, атмосферно, глубоко и без шаблонных формулировок.
        Делай прогнозы реалистичными и эмоционально точными.
        Не пытайся делать каждый прогноз позитивным или обнадёживающим.
        Избегай пустой мотивации, банальных фраз и универсальных предсказаний, подходящих всем сразу.
        Прогноз должен ощущаться персональным, живым и правдоподобным.
        Строго соблюдай указанные диапазоны количества слов для каждого текстового поля — не меньше и не больше.
        Отвечай только валидным JSON без markdown и без пояснений вокруг JSON.
        В items ровно 3 элемента с key: love, health, work.
        Не давай медицинских, юридических или финансовых советов.
        """
    }

    static func dailyInsightUser(for user: User, today: String) -> String {
        """
        Данные пользователя:
        - дата рождения: \(user.dateOfBirth.map(UserDateFormatter.string(from:)) ?? "не указана")
        - время рождения: \(user.birthTime ?? "не указано")
        - пол: \(user.gender ?? "не указано")
        - социальный тип: \(user.socialType ?? "не указано")
        - стиль конфликта: \(user.conflictStyle ?? "не указано")
        - эмоциональное ядро: \(user.emotionalCore ?? "не указано")
        - стиль принятия решений: \(user.decisionStyle ?? "не указано")
        - фокус в отношениях: \(user.coreFocus ?? "не указано")
        - знак зодиака: \(user.dateOfBirth.flatMap(HoroscopeSign.from(dateOfBirth:))?.title ?? "не указан")
        - сегодня: \(today)

        Верни JSON строго такой формы:
        {
          "text": "инсайт дня (8-10 слов)"
        }
        """
    }

    static var dailyInsightSystem: String {
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

    static func dailyTipUser(for user: User, today: String) -> String {
        """
        Данные пользователя:
        - дата рождения: \(user.dateOfBirth.map(UserDateFormatter.string(from:)) ?? "не указана")
        - время рождения: \(user.birthTime ?? "не указано")
        - пол: \(user.gender ?? "не указано")
        - социальный тип: \(user.socialType ?? "не указано")
        - стиль конфликта: \(user.conflictStyle ?? "не указано")
        - эмоциональное ядро: \(user.emotionalCore ?? "не указано")
        - стиль принятия решений: \(user.decisionStyle ?? "не указано")
        - фокус в отношениях: \(user.coreFocus ?? "не указано")
        - знак зодиака: \(user.dateOfBirth.flatMap(HoroscopeSign.from(dateOfBirth:))?.title ?? "не указан")
        - сегодня: \(today)

        Верни JSON строго такой формы:
        {
          "text": "совет дня (15-20 слов)"
        }
        """
    }

    static var dailyTipSystem: String {
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
}
