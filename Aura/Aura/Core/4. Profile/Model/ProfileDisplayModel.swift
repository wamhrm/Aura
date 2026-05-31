//
//  ProfileDisplayModel.swift
//  Aura
//
//  Created by ddorsat on 28.05.2026.
//

import Foundation

struct BestCompatibilityDisplay: Equatable {
    let partnerZodiacSign: String
    let partnerName: String
    let score: Int
}

struct ProfileDisplayModel: Equatable {
    let dailyTip: String
    let overview: String
    let socialFilter: String
    let emotionalDepth: String
    let temperament: Int
    let thinking: Int
    let organization: Int
    let relationships: Int
    let zodiacSignTitle: String?
    let bestCompatibility: BestCompatibilityDisplay?
}

extension ProfileDisplayModel {
    static let placeholder = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil)
    
    static func make(personalityResult: PersonalityResultModel?,
                     dailyTip: DailyContentModel?,
                     history: [HistoryCellModel] = []) -> ProfileDisplayModel {
        ProfileDisplayModel(
            dailyTip: dailyTip?.text ?? ProfileDisplayPlaceholder.dailyTip,
            overview: personalityResult?.overview.description ?? ProfileDisplayPlaceholder.overview,
            socialFilter: sectionItem(.socialFilter, from: personalityResult) ?? ProfileDisplayPlaceholder.socialFilter,
            emotionalDepth: sectionItem(.emotionalDepth, from: personalityResult) ?? ProfileDisplayPlaceholder.emotionalDepth,
            temperament: barValue(.temperament, from: personalityResult) ?? ProfileDisplayPlaceholder.temperament,
            thinking: barValue(.thinking, from: personalityResult) ?? ProfileDisplayPlaceholder.thinking,
            organization: barValue(.organization, from: personalityResult) ?? ProfileDisplayPlaceholder.organization,
            relationships: barValue(.relationships, from: personalityResult) ?? ProfileDisplayPlaceholder.relationships,
            zodiacSignTitle: zodiacSignTitle(from: personalityResult?.zodiacSign),
            bestCompatibility: bestCompatibility(from: history))
    }

    private static func sectionItem(_ title: PersonalityCellTypes,
                                    from result: PersonalityResultModel?) -> String? {
        result?.sections.flatMap(\.items).first(where: { $0.title == title })?.description
    }

    private static func barValue(_ title: EmotionalProfileTypes,
                                 from result: PersonalityResultModel?) -> Int? {
        result?.emotionalBar.first(where: { $0.title == title })?.value
    }

    private static func bestCompatibility(from history: [HistoryCellModel]) -> BestCompatibilityDisplay? {
        history
            .filter { $0.kind == .compatibility }
            .compactMap(\.compatibilityResult)
            .max(by: { $0.compatibilityScore < $1.compatibilityScore })
            .map {
                BestCompatibilityDisplay(partnerZodiacSign: $0.partnerZodiacSign,
                                         partnerName: $0.partnerNameCapitalized,
                                         score: $0.compatibilityScore)
            }
    }

    private static func zodiacSignTitle(from sign: String?) -> String? {
        guard let sign else { return nil }
        return HoroscopeTypes.allCases
            .first { $0.icon.contains(sign) || sign.contains($0.icon) }?.rawValue
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
