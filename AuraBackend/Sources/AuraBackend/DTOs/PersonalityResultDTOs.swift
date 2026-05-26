//
//  PersonalityResultDTOs.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Vapor

struct PersonalityResultDTO: Content {
    let name: String
    let zodiacSign: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityOverview
    let emotionalBar: [PersonalityEmotionalBar]
    let sections: [PersonalitySection]
}

struct PersonalityOverview: Content, Codable {
    let title: String
    let description: String
}

struct PersonalityEmotionalBar: Content, Codable {
    let title: String
    let value: Int
}

struct PersonalitySection: Content, Codable {
    let selectedTest: String
    let description: String
    let items: [PersonalitySectionItems]
}

struct PersonalitySectionItems: Content, Codable {
    let title: String
    let description: String
}

struct PersonalityTestContent: Codable {
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityOverview
    let emotionalBar: [PersonalityEmotionalBar]
    let sections: [PersonalitySection]
}

enum PersonalityTests: String, CaseIterable {
    case astrology
    case behavioralPatterns
    case decisionMaking
    case attachmentStyle
    case idealPartner
    case loveLanguage

    var title: String {
        switch self {
            case .astrology:
                return "Астрология"
            case .behavioralPatterns:
                return "Поведенческие паттерны"
            case .decisionMaking:
                return "Стиль принятия решений"
            case .attachmentStyle:
                return "Стиль привязанности"
            case .idealPartner:
                return "Идеальный партнер"
            case .loveLanguage:
                return "Язык любви"
        }
    }

    private static func from(title: String) -> PersonalityTests? {
        return allCases.first { $0.title == title }
    }

    static func from(titles: [String]) -> [PersonalityTests]? {
        var mapped: [PersonalityTests] = []

        for title in titles {
            guard let test = from(title: title) else { return nil }
            mapped.append(test)
        }

        return mapped
    }
}

enum PersonalityItems {
    private static let behavioralPatterns = ["Социальный фильтр", "Источник истощения"]
    private static let decisionMaking = ["Баланс логики", "Фактор интуиции"]
    private static let attachmentStyle = ["Потребность в автономии", "База безопасности"]
    private static let idealPartner = ["Интеллектуальная схожесть", "Глубина связи"]
    private static let astrology = ["Глубина связи", "Фактор интуиции"]
    private static let loveLanguage = ["Глубина связи", "Интеллектуальная схожесть"]

    static func allowed(for test: PersonalityTests) -> [String] {
        switch test {
            case .behavioralPatterns:
                return behavioralPatterns
            case .decisionMaking:
                return decisionMaking
            case .attachmentStyle:
                return attachmentStyle
            case .idealPartner:
                return idealPartner
            case .astrology:
                return astrology
            case .loveLanguage:
                return loveLanguage
        }
    }
}
