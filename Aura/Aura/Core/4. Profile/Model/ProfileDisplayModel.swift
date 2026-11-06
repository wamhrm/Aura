//
//  ProfileDisplayModel.swift
//  Aura
//
//  Created by wamhrm on 28.05.2026.
//

import Foundation

struct ProfileDisplayModel: Equatable {
    let dailyTip: String?
    let overview: String?
    let socialFilter: String?
    let emotionalDepth: String?
    let temperament: Int?
    let thinking: Int?
    let organization: Int?
    let relationships: Int?

    var hasTopics: Bool {
        socialFilter != nil || emotionalDepth != nil
    }

    var hasBothTopics: Bool {
        socialFilter != nil && emotionalDepth != nil
    }
}

extension ProfileDisplayModel {
    // Sample text for the locked screen, it only ever appears behind the blur
    static let placeholder = ProfileDisplayModel(dailyTip: ProfileDisplayPlaceholder.dailyTip,
                                                 overview: ProfileDisplayPlaceholder.overview,
                                                 socialFilter: ProfileDisplayPlaceholder.socialFilter,
                                                 emotionalDepth: ProfileDisplayPlaceholder.emotionalDepth,
                                                 temperament: ProfileDisplayPlaceholder.temperament,
                                                 thinking: ProfileDisplayPlaceholder.thinking,
                                                 organization: ProfileDisplayPlaceholder.organization,
                                                 relationships: ProfileDisplayPlaceholder.relationships)

    static func make(personalityResult: PersonalityResultModel?,
                     dailyTip: DailyContentModel?) -> ProfileDisplayModel {
        ProfileDisplayModel(
            dailyTip: dailyTip?.text,
            overview: personalityResult?.overview.description,
            socialFilter: sectionItem(.socialFilter, result: personalityResult),
            emotionalDepth: sectionItem(.emotionalDepth, result: personalityResult),
            temperament: barValue(.temperament, result: personalityResult),
            thinking: barValue(.thinking, result: personalityResult),
            organization: barValue(.organization, result: personalityResult),
            relationships: barValue(.relationships, result: personalityResult))
    }

    private static func sectionItem(_ key: PersonalityCellTypes,
                                    result: PersonalityResultModel?) -> String? {
        result?.sections.flatMap(\.items).first(where: { $0.key == key })?.description
    }

    private static func barValue(_ key: EmotionalProfileTypes,
                                 result: PersonalityResultModel?) -> Int? {
        result?.emotionalBar.first(where: { $0.key == key })?.value
    }
}

fileprivate enum ProfileDisplayPlaceholder {
    static let dailyTip = "Не пытайся быть продуктивным весь день. Сделай одну реально важную вещь без отвлечений — остальное шум и самообман."
    static let overview = "Интуитивный креатор. Глубокий интроверт с мощной интуицией, который ищет настоящую связь, а не светскую болтовню."
    static let socialFilter = "Обладает встроенным детектором на пустую болтовню."
    static let emotionalDepth = "Чувства раскрываются постепенно, но очень надолго."
    static let temperament = 6
    static let thinking = 2
    static let organization = 8
    static let relationships = 8
}
