//
//  HoroscopeDTOs.swift
//  AuraServer
//
//  Created by ddorsat on 21.05.2026.
//

import Vapor

struct HoroscopeDTO: Content {
    let id: UUID
    let type: String
    let dateStart: String
    let dateEnd: String
    let description: String
    let items: [HoroscopeItem]
}

struct HoroscopeItem: Content, Codable {
    let title: String
    let description: String
}

struct CreateHoroscopeRequest: Content {
    let sign: String
}

struct HoroscopeGeneratedContent: Codable {
    let description: String
    let items: [HoroscopeItem]
}

enum HoroscopeSign: String, Codable, CaseIterable {
    case aries = "Овен"
    case taurus = "Телец"
    case gemini = "Близнецы"
    case cancer = "Рак"
    case leo = "Лев"
    case virgo = "Дева"
    case libra = "Весы"
    case scorpio = "Скорпион"
    case sagittarius = "Стрелец"
    case capricorn = "Козерог"
    case aquarius = "Водолей"
    case pisces = "Рыбы"

    static func from(title: String) -> HoroscopeSign? {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return HoroscopeSign(rawValue: normalized)
    }

    static func from(dateOfBirth: Date) -> HoroscopeSign? {
        let calendar = Calendar(identifier: .gregorian)
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
    static func map(_ horoscope: Horoscope) throws -> HoroscopeDTO {
        guard let id = horoscope.id else {
            throw Abort(.internalServerError, reason: "Гороскоп без идентификатора")
        }

        return HoroscopeDTO(id: id,
                            type: horoscope.sign,
                            dateStart: horoscope.dateStart,
                            dateEnd: horoscope.dateEnd,
                            description: horoscope.description,
                            items: horoscope.items)
    }
}
