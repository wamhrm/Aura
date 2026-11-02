//
//  HoroscopeDTOs.swift
//  AuraBackend
//
//  Created by wamhrm on 21.05.2026.
//

import Foundation
import Vapor

struct HoroscopeDTO: Content {
    let id: UUID
    let type: String
    let dateStart: String
    let dateEnd: String
    let description: String
    let items: [HoroscopeItems]
}

struct HoroscopeItems: Content {
    let key: String
    let description: String
}

struct HoroscopeContentResult: Codable {
    let description: String
    let items: [HoroscopeItems]
}

enum HoroscopeSign: String, CaseIterable {
    case aries, taurus, gemini, cancer, leo, virgo, libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var title: String {
        switch self {
            case .aries: return "Овен"
            case .taurus: return "Телец"
            case .gemini: return "Близнецы"
            case .cancer: return "Рак"
            case .leo: return "Лев"
            case .virgo: return "Дева"
            case .libra: return "Весы"
            case .scorpio: return "Скорпион"
            case .sagittarius: return "Стрелец"
            case .capricorn: return "Козерог"
            case .aquarius: return "Водолей"
            case .pisces: return "Рыбы"
        }
    }

    static func from(dateOfBirth: Date) -> HoroscopeSign? {
        // Birth dates are stored as midnight UTC, the server's own time zone must not move them to another day
        let calendar = UserDateFormatter.calendar
        let day = calendar.component(.day, from: dateOfBirth)
        let month = calendar.component(.month, from: dateOfBirth)

        switch (month, day) {
            case (1, 20...31), (2, 1...18):
                return .aquarius
            case (2, 19...29), (3, 1...20):
                return .pisces
            case (3, 21...31), (4, 1...19):
                return .aries
            case (4, 20...30), (5, 1...20):
                return .taurus
            case (5, 21...31), (6, 1...20):
                return .gemini
            case (6, 21...30), (7, 1...22):
                return .cancer
            case (7, 23...31), (8, 1...22):
                return .leo
            case (8, 23...31), (9, 1...22):
                return .virgo
            case (9, 23...30), (10, 1...22):
                return .libra
            case (10, 23...31), (11, 1...21):
                return .scorpio
            case (11, 22...30), (12, 1...21):
                return .sagittarius
            case (12, 22...31), (1, 1...19):
                return .capricorn
            default:
                return nil
        }
    }
}

enum HoroscopeDTOMapper {
    static let sphereKeys = ["love", "health", "work"]

    static func map(_ horoscope: Horoscope) throws -> HoroscopeDTO {
        guard let id = horoscope.id else {
            throw Abort(.internalServerError, reason: "Гороскоп без идентификатора")
        }

        return HoroscopeDTO(id: id,
                            type: horoscope.sign,
                            dateStart: horoscope.dateStart,
                            dateEnd: horoscope.dateEnd,
                            description: horoscope.description,
                            items: try decodeItems(from: horoscope.items))
    }

    static func encodeItems(_ items: [HoroscopeItems]) throws -> String {
        let data = try JSONEncoder().encode(try normalizeItems(items))
        guard let json = String(data: data, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Не удалось сохранить сферы гороскопа")
        }
        return json
    }

    private static func decodeItems(from json: String) throws -> [HoroscopeItems] {
        guard let data = json.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Не удалось прочитать сферы гороскопа")
        }
        return try normalizeItems(try JSONDecoder().decode([HoroscopeItems].self, from: data))
    }

    private static func normalizeItems(_ items: [HoroscopeItems]) throws -> [HoroscopeItems] {
        var descriptions: [String: String] = [:]

        for item in items {
            let description = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !description.isEmpty else { continue }

            descriptions[item.key] = description
        }

        let normalized = sphereKeys.compactMap { key -> HoroscopeItems? in
            guard let description = descriptions[key] else { return nil }
            return HoroscopeItems(key: key, description: description)
        }

        guard normalized.count == sphereKeys.count else {
            throw Abort(.badGateway, reason: "OpenAI вернул ответ в неожиданном формате")
        }

        return normalized
    }
}
