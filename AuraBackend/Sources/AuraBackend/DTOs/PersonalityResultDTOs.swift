//
//  PersonalityResultDTOs.swift
//  AuraBackend
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

struct PersonalityOverview: Content {
    let title: String
    let description: String
}

struct PersonalityEmotionalBar: Content {
    let title: String
    let value: Int
}

struct PersonalitySection: Content {
    let selectedTest: String
    let description: String
    let items: [PersonalitySectionItems]
}

struct PersonalitySectionItems: Content {
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
        allCases.first { $0.title == title }
    }

    static func from(titles: [String]) -> [PersonalityTests]? {
        let mapped = titles.compactMap(from(title:))
        return mapped.count == titles.count ? mapped : nil
    }
}

enum PersonalityItems {
    private static let astrology = ["Анализ натальной карты", "Планетарные аспекты"]
    private static let behavioralPatterns = ["Социальный фильтр", "Источник истощения"]
    private static let decisionMaking = ["Баланс логики", "Фактор интуиции"]
    private static let attachmentStyle = ["Потребность в автономии", "База безопасности"]
    private static let idealPartner = ["Интеллектуальная схожесть", "Глубина связи"]
    private static let loveLanguage = ["Способы проявления чувств", "Эмоциональные потребности"]

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
