//
//  PersonalityResultDTOs.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
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
    static let keys = ["temperament", "thinking", "organization", "relationships"]

    let key: String
    let value: Int
}

struct PersonalitySection: Content {
    let selectedTest: String
    let description: String
    let items: [PersonalitySectionItems]
}

struct PersonalitySectionItems: Content {
    let key: String
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
    static let minSelected = 2

    case astrology, behavioralPatterns, decisionMaking, attachmentStyle, idealPartner, loveLanguage

    var title: String {
        switch self {
            case .astrology:
                return "Астрологический портрет"
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

    static func from(keys: [String]) -> [PersonalityTests]? {
        let mapped = keys.compactMap(PersonalityTests.init(rawValue:))
        return mapped.count == keys.count ? mapped : nil
    }
}

enum PersonalityItems: String, CaseIterable {
    case natalChart, planetaryAspects, socialFilter, energyDrain, logicBalance, intuitionFactor, autonomyNeed, securityBase, intellectualMatch, emotionalDepth, loveExpression, emotionalNeeds

    var title: String {
        switch self {
            case .natalChart:
                return "Черты вашего знака"
            case .planetaryAspects:
                return "Знак и ваш характер"
            case .socialFilter:
                return "Социальный фильтр"
            case .energyDrain:
                return "Источник истощения"
            case .logicBalance:
                return "Баланс логики"
            case .intuitionFactor:
                return "Фактор интуиции"
            case .autonomyNeed:
                return "Потребность в автономии"
            case .securityBase:
                return "База безопасности"
            case .intellectualMatch:
                return "Интеллектуальная схожесть"
            case .emotionalDepth:
                return "Глубина связи"
            case .loveExpression:
                return "Способы проявления чувств"
            case .emotionalNeeds:
                return "Эмоциональные потребности"
        }
    }

    static func allowed(for test: PersonalityTests) -> [PersonalityItems] {
        switch test {
            case .astrology:
                return [.natalChart, .planetaryAspects]
            case .behavioralPatterns:
                return [.socialFilter, .energyDrain]
            case .decisionMaking:
                return [.logicBalance, .intuitionFactor]
            case .attachmentStyle:
                return [.autonomyNeed, .securityBase]
            case .idealPartner:
                return [.intellectualMatch, .emotionalDepth]
            case .loveLanguage:
                return [.loveExpression, .emotionalNeeds]
        }
    }
}
