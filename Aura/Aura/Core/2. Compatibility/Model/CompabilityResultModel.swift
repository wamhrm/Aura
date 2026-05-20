//
//  CompabilityResultModel.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import Foundation

struct CompatibilityTestRequest: Encodable {
    let partnerName: String
    let partnerDateOfBirth: String?
    let partnerBirthTime: String?
    let partnerAge: String?
    let partnerGender: String
    let exactDateOfBirth: Bool
    let selectedTests: [String]
}

struct CompabilityResultModel: Decodable, Hashable {
    let userName: String
    let userZodiacSign: String
    let partnerName: String
    let partnerZodiacSign: String
    let compatibilityScore: Int
    let selectedTests: [CompatibilityTestTypes]
    let title: String
    let subtitle: String
    let overview: CompatibilityOverview
    let emotionalBar: [CompatibilityEmotionalBar]
    let sections: [CompatibilitySection]
    let forecast: CompatibilityForecast
}

struct CompatibilityOverview: Decodable, Hashable {
    let title: String
    let description: String
}

struct CompatibilityEmotionalBar: Decodable, Hashable {
    let title: EmotionalProfileTypes
    let value: Int
}

struct CompatibilitySection: Decodable, Hashable {
    let selectedTest: CompatibilityTestTypes
    let description: String
    let items: [CompatibilitySectionItem]
}

struct CompatibilitySectionItem: Decodable, Hashable {
    let title: CompatibilityCellTypes
    let description: String
}

struct CompatibilityForecast: Decodable, Hashable {
    let recognitionTitle: String
    let recognitionDescription: String
    let potentialTitle: String
    let potentialDescription: String
}

extension CompabilityResultModel {
    static let mock = CompabilityResultModel(
        userName: "Роберт",
        userZodiacSign: "♑️",
        partnerName: "Мария",
        partnerZodiacSign: "♑️",
        compatibilityScore: 75,
        selectedTests: [.behavioralPatterns, .attachmentCompatibility],
        title: "Интенсивная, но стабильная связь",
        subtitle: "Вы ищете близость. Они защищают дистанцию.",
        overview: CompatibilityOverview(
            title: "Основная динамика",
            description: "Между вами нет хаоса ради эмоций — связь строится на ощущении надёжности, уважения и внутреннего спокойствия."
        ),
        emotionalBar: [
            CompatibilityEmotionalBar(title: .emotionalResonance, value: 3),
            CompatibilityEmotionalBar(title: .innerOpenness, value: 7),
            CompatibilityEmotionalBar(title: .soulAlignment, value: 5),
            CompatibilityEmotionalBar(title: .emotionalWarmth, value: 9)
        ],
        sections: [
            CompatibilitySection(
                selectedTest: .behavioralPatterns,
                description: "Вы оба замечаете изменения в настроении партнёра раньше, чем он сам успевает об этом сказать.",
                items: [
                    CompatibilitySectionItem(
                        title: .dominanceDynamics,
                        description: "В отношениях нет явного лидера — влияние постоянно переходит от одного к другому."
                    ),
                    CompatibilitySectionItem(
                        title: .emotionalResonance,
                        description: "Вы быстро считываете эмоциональное состояние друг друга даже в тишине."
                    )
                ]
            )
        ],
        forecast: CompatibilityForecast(
            recognitionTitle: "Редкое узнавание",
            recognitionDescription: "С самого начала возникло ощущение, будто вы уже давно знакомы друг с другом.",
            potentialTitle: "Стабильный союз",
            potentialDescription: "У этой связи высокий потенциал для долгих отношений без эмоциональных качелей."
        )
    )
}
