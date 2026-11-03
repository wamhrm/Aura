//
//  CompatibilityResultDTOs.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Vapor

struct CompatibilityTestRequest: Content {
    let partnerName: String
    let partnerDateOfBirth: String
    let partnerBirthTime: String?
    let partnerGender: String
    let partnerSocialType: String
    let partnerConflictStyle: String
    let partnerEmotionalCore: String
    let partnerDecisionStyle: String
    let partnerCoreFocus: String
    let selectedTests: [String]
}

struct CompatibilityResultDTO: Content {
    let userName: String
    let userZodiacSign: String
    let partnerName: String
    let partnerZodiacSign: String?
    let compatibilityScore: Int
    let selectedTests: [String]
    let title: String
    let subtitle: String
    let overview: CompatibilityOverview
    let emotionalBar: [CompatibilityEmotionalBar]
    let sections: [CompatibilitySection]
    let forecast: CompatibilityForecast
}

struct CompatibilityOverview: Content {
    let title: String
    let description: String
}

struct CompatibilityEmotionalBar: Content {
    static let keys = ["emotionalResonance", "innerOpenness", "soulAlignment", "emotionalWarmth"]

    let key: String
    let value: Int
}

struct CompatibilitySection: Content {
    let selectedTest: String
    let description: String
    let items: [CompatibilitySectionItem]
}

struct CompatibilitySectionItem: Content {
    let key: String
    let description: String
}

struct CompatibilityForecast: Content {
    let recognitionTitle: String
    let recognitionDescription: String
    let potentialTitle: String
    let potentialDescription: String
}

struct CompatibilityTestContent: Codable {
    let title: String
    let subtitle: String
    let overview: CompatibilityOverview
    let emotionalBar: [CompatibilityEmotionalBar]
    let sections: [CompatibilitySection]
    let forecast: CompatibilityForecast
}

enum CompatibilityTests: String, CaseIterable {
    static let minSelected = 3

    case astrology, behavioralPatterns, attachmentCompatibility, loveLanguages, conflictResolution

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
        }
    }

    static func from(keys: [String]) -> [CompatibilityTests]? {
        let mapped = keys.compactMap(CompatibilityTests.init(rawValue:))
        return mapped.count == keys.count ? mapped : nil
    }
}

enum CompatibilityItems: String, CaseIterable {
    case synastry, karmicLesson, dominanceDynamics, emotionalResonance, attachmentBond, comfortDistance, languageMatch, translationNeeds, conflictMechanics, peaceRecovery

    var title: String {
        switch self {
            case .synastry:
                return "Совместимость знаков"
            case .karmicLesson:
                return "Кармический урок"
            case .dominanceDynamics:
                return "Динамика лидерства"
            case .emotionalResonance:
                return "Эмоциональный резонанс"
            case .attachmentBond:
                return "Сцепка типов"
            case .comfortDistance:
                return "Дистанция комфорта"
            case .languageMatch:
                return "Совпадение языков"
            case .translationNeeds:
                return "Трудности перевода"
            case .conflictMechanics:
                return "Механика ссор"
            case .peaceRecovery:
                return "Скорость примирения"
        }
    }

    static func allowed(for test: CompatibilityTests) -> [CompatibilityItems] {
        switch test {
            case .astrology:
                return [.synastry, .karmicLesson]
            case .behavioralPatterns:
                return [.dominanceDynamics, .emotionalResonance]
            case .attachmentCompatibility:
                return [.attachmentBond, .comfortDistance]
            case .loveLanguages:
                return [.languageMatch, .translationNeeds]
            case .conflictResolution:
                return [.conflictMechanics, .peaceRecovery]
        }
    }
}
