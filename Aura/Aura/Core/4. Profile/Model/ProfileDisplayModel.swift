//
//  ProfileDisplayModel.swift
//  Aura
//
//  Created by ddorsat on 28.05.2026.
//

import Foundation

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

    static let placeholder = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil)

    static func make(personalityResult: PersonalityResultModel?,
                     dailyTip: DailyContentModel?) -> ProfileDisplayModel {
        ProfileDisplayModel(
            dailyTip: dailyTip?.text ?? ProfileDisplayPlaceholder.dailyTip,
            overview: personalityResult?.overview.description ?? ProfileDisplayPlaceholder.overview,
            socialFilter: personalityResult?.sections.flatMap(\.items)
                .first(where: { $0.title == .socialFilter })?.description ?? ProfileDisplayPlaceholder.socialFilter,
            emotionalDepth: personalityResult?.sections.flatMap(\.items)
                .first(where: { $0.title == .emotionalDepth })?.description ?? ProfileDisplayPlaceholder.emotionalDepth,
            temperament: personalityResult?.emotionalBar.first(where: { $0.title == .temperament })?.value
                ?? ProfileDisplayPlaceholder.temperament,
            thinking: personalityResult?.emotionalBar.first(where: { $0.title == .thinking })?.value
                ?? ProfileDisplayPlaceholder.thinking,
            organization: personalityResult?.emotionalBar.first(where: { $0.title == .organization })?.value
                ?? ProfileDisplayPlaceholder.organization,
            relationships: personalityResult?.emotionalBar.first(where: { $0.title == .relationships })?.value
                ?? ProfileDisplayPlaceholder.relationships,
            zodiacSignTitle: zodiacSignTitle(from: personalityResult?.zodiacSign))
    }

    private static func zodiacSignTitle(from sign: String?) -> String? {
        guard let sign else { return nil }
        return HoroscopeType.allCases
            .first { $0.icon.contains(sign) || sign.contains($0.icon) }?.rawValue
    }
}

enum ProfileDisplayPlaceholder {
    static let dailyTip = "Не пытайся быть продуктивным весь день. Сделай одну реально важную вещь без отвлечений — остальное шум и самообман."
    static let overview = "Интуитивный креатор. Глубокий интроверт с мощной интуицией, который ищет настоящую связь, а не светскую болтовню."
    static let socialFilter = "Обладает встроенным детектором на пустую болтовню."
    static let emotionalDepth = "Чувства раскрываются постепенно, но очень надолго."
    static let temperament = 6
    static let thinking = 2
    static let organization = 8
    static let relationships = 8
}
