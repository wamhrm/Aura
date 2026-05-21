//
//  CompatibilityResultDTOs.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Vapor

struct CompatibilityTestRequest: Content {
    let partnerName: String
    let partnerDateOfBirth: String?
    let partnerBirthTime: String?
    let partnerAge: String?
    let partnerGender: String
    let exactDateOfBirth: Bool
    let selectedTests: [String]
}

struct CompatibilityResultDTO: Content {
    let userName: String
    let userZodiacSign: String
    let partnerName: String
    let partnerZodiacSign: String
    let compatibilityScore: Int
    let selectedTests: [String]
    let title: String
    let subtitle: String
    let overview: CompatibilityOverview
    let emotionalBar: [CompatibilityEmotionalBar]
    let sections: [CompatibilitySection]
    let forecast: CompatibilityForecast
}

struct CompatibilityOverview: Content, Codable {
    let title: String
    let description: String
}

struct CompatibilityEmotionalBar: Content, Codable {
    let title: String
    let value: Int
}

struct CompatibilitySection: Content, Codable {
    let selectedTest: String
    let description: String
    let items: [CompatibilitySectionItem]
}

struct CompatibilitySectionItem: Content, Codable {
    let title: String
    let description: String
}

struct CompatibilityForecast: Content, Codable {
    let recognitionTitle: String
    let recognitionDescription: String
    let potentialTitle: String
    let potentialDescription: String
}

struct CompatibilityTestContent: Codable {
    let title: String
    let subtitle: String
    let compatibilityScore: Int
    let overview: CompatibilityOverview
    let emotionalBar: [CompatibilityEmotionalBar]
    let sections: [CompatibilitySection]
    let forecast: CompatibilityForecast
}

enum CompatibilityTests: String, CaseIterable {
    case astrology
    case behavioralPatterns
    case attachmentCompatibility
    case loveLanguages
    case conflictResolution
    case sexualCompatibility

    var title: String {
        switch self {
            case .astrology:
                return "Астрология пары"
            case .behavioralPatterns:
                return "Поведенческие паттерны"
            case .attachmentCompatibility:
                return "Стили привязанности"
            case .loveLanguages:
                return "Языки любви"
            case .conflictResolution:
                return "Конфликты и примирение"
            case .sexualCompatibility:
                return "Сексуальная совместимость"
        }
    }

    private static func from(title: String) -> CompatibilityTests? {
        allCases.first { $0.title == title }
    }

    static func from(titles: [String]) -> [CompatibilityTests]? {
        var mapped: [CompatibilityTests] = []

        for title in titles {
            guard let test = from(title: title) else { return nil }
            mapped.append(test)
        }

        return mapped
    }
}

enum CompatibilityItems {
    private static let astrology = ["Синастрия знаков", "Кармический урок"]
    private static let behavioralPatterns = ["Динамика лидерства", "Эмоциональный резонанс"]
    private static let attachmentCompatibility = ["Сцепка типов", "Дистанция комфорта"]
    private static let loveLanguages = ["Совпадение языков", "Трудности перевода"]
    private static let conflictResolution = ["Механика ссор", "Скорость примирения"]
    private static let sexualCompatibility = ["Сексуальный темперамент", "Сексуальная химия"]

    static func allowed(for test: CompatibilityTests) -> [String] {
        switch test {
            case .astrology:
                return astrology
            case .behavioralPatterns:
                return behavioralPatterns
            case .attachmentCompatibility:
                return attachmentCompatibility
            case .loveLanguages:
                return loveLanguages
            case .conflictResolution:
                return conflictResolution
            case .sexualCompatibility:
                return sexualCompatibility
        }
    }
}
