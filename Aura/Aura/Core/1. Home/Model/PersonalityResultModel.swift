//
//  PersonalityResultModel.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Foundation

struct PersonalityResultModel: Codable, Hashable {
    let name: String
    let zodiacSign: HoroscopeTypes
    let selectedTests: [PersonalityTestTypes]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityOverview
    let emotionalBar: [PersonalityEmotionalBar]
    let sections: [PersonalitySection]

    var nameCapitalized: String {
        name.capitalized
    }
}

struct PersonalityOverview: Codable, Hashable {
    let title: String
    let description: String
}

struct PersonalityEmotionalBar: Codable, Hashable {
    let key: EmotionalProfileTypes
    let value: Int
}

struct PersonalitySection: Hashable, Codable {
    let selectedTest: PersonalityTestTypes
    let description: String
    let items: [PersonalitySectionItems]
}

struct PersonalitySectionItems: Hashable, Codable {
    let key: PersonalityCellTypes
    let description: String
}

extension PersonalityResultModel {
    static let mock = PersonalityResultModel(
        name: "Дмитрий",
        zodiacSign: .aquarius,
        selectedTests: [.astrology, .attachmentStyle],
        archetypeTitle: "Интуитивный креатор",
        archetypeSubtitle: "Вы стремитесь к глубине и аутентичности в своих связях",
        overview: PersonalityOverview(title: "Основная характеристика",
                                             description: "Ты — интроверт с сильной интуицией, который в отношениях ищет глубину, но быстро выгорает от поверхностного трепа. Астрология и нумерология показывают, что у тебя сейчас период трансформации"),
        emotionalBar: [PersonalityEmotionalBar(key: .temperament, value: 7),
                       PersonalityEmotionalBar(key: .thinking, value: 8),
                       PersonalityEmotionalBar(key: .organization, value: 6),
                       PersonalityEmotionalBar(key: .relationships, value: 4)],
        sections: [PersonalitySection(
            selectedTest: .astrology,
            description: "Ваш знак задаёт глубину чувствительности и способ воспринимать близость.",
            items: [PersonalitySectionItems(key: .natalChart,
                                            description: "В натальной карте сильны интуиция и потребность в смысле."),
                    PersonalitySectionItems(key: .planetaryAspects,
                                            description: "Планетарные акценты усиливают внутренние перепады настроения.")]),
                   PersonalitySection(
            selectedTest: .attachmentStyle,
            description: "Вы стремитесь к надёжной связи, но сохраняете личное пространство.",
            items: [PersonalitySectionItems(key: .autonomyNeed,
                                            description: "Вам важно чувствовать эмоциональную вовлечённость партнёра."),
                    PersonalitySectionItems(key: .securityBase,
                                            description: "Вы комфортно чувствуете себя, когда есть время на себя.")])])
}
