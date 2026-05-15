//
//  PersonalityResultModel.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import Foundation

struct PersonalityResultModel: Decodable {
    let name: String
    let zodiacSign: String
    let selectedTests: [PersonalityTestTypes]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityOverview
    let emotionalBar: [PersonalityEmotionalBar]
    let sections: [PersonalitySection]
}

struct PersonalityOverview: Decodable {
    let title: String
    let description: String
}

struct PersonalityEmotionalBar: Decodable, Hashable {
    let title: EmotionalProfileTypes
    let value: Int
}

struct PersonalitySection: Hashable, Decodable {
    let selectedTest: PersonalityTestTypes
    let description: String
    let items: [PersonalitySectionItems]
}

struct PersonalitySectionItems: Hashable, Decodable {
    let title: PersonalityCellTypes
    let description: String
}

extension PersonalityResultModel {
    static let mock = PersonalityResultModel(
        name: "Дмитрий",
        zodiacSign: "♒",
        selectedTests: [.astrology, .attachmentStyle],
        archetypeTitle: "Интуитивный креатор",
        archetypeSubtitle: "Вы стремитесь к глубине и аутентичности в своих связях",
        overview: PersonalityOverview(title: "Основная характеристика",
                                             description: "Ты — интроверт с сильной интуицией, который в отношениях ищет глубину, но быстро выгорает от поверхностного трепа. Астрология и нумерология показывают, что у тебя сейчас период трансформации"),
        emotionalBar: [PersonalityEmotionalBar(title: .temperament, value: 7),
                       PersonalityEmotionalBar(title: .thinking, value: 8),
                       PersonalityEmotionalBar(title: .organization, value: 6),
                       PersonalityEmotionalBar(title: .relationships, value: 4)],
        sections: [PersonalitySection(
            selectedTest: .attachmentStyle,
            description: "Вы стремитесь к надёжной связи, но сохраняете личное пространство.",
            items: [PersonalitySectionItems(title: .autonomyNeed,
                                            description: "Вам важно чувствовать эмоциональную вовлечённость партнёра."),
                    PersonalitySectionItems(title: .energyDrain,
                                            description: "Вы комфортно чувствуете себя, когда есть время на себя.")]),
                   PersonalitySection(
            selectedTest: .behavioralPatterns,
            description: "Вы стремитесь к надёжной связи, но сохраняете личное пространство.",
            items: [PersonalitySectionItems(title: .securityBase,
                                            description: "Вам важно чувствовать эмоциональную вовлечённость партнёра."),
                    PersonalitySectionItems(title: .intellectualMatch,
                                            description: "Вы комфортно чувствуете себя, когда есть время на себя.")])])
}
