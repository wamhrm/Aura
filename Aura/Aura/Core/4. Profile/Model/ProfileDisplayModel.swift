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
    static var placeholder: ProfileDisplayModel {
        ProfileDisplayModel(
            dailyTip: AppLanguage.text("Не пытайся быть продуктивным весь день. Сделай одну реально важную вещь без отвлечений — остальное шум и самообман."),
            overview: AppLanguage.text("Интуитивный креатор. Глубокий интроверт с мощной интуицией, который ищет настоящую связь, а не светскую болтовню."),
            socialFilter: AppLanguage.text("Обладает встроенным детектором на пустую болтовню."),
            emotionalDepth: AppLanguage.text("Чувства раскрываются постепенно, но очень надолго."),
            temperament: 6,
            thinking: 2,
            organization: 8,
            relationships: 8)
    }

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
