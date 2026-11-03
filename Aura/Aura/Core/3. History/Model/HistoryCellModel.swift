//
//  HistoryCellModel.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Foundation

struct HistoryCellModel: Codable, Identifiable, Hashable {
    let id: UUID
    let kind: HistoryTestKind
    let createdAt: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let zodiacSign: HoroscopeTypes
    let compatibilityScore: Int?
    let partnerName: String?
    let partnerZodiacSign: HoroscopeTypes?
    let personalityResult: PersonalityResultModel?
    let compatibilityResult: CompatibilityResultModel?
}

enum HistoryTestKind: String, Codable, Hashable {
    case personality, compatibility
}

extension HistoryCellModel {
    static let personalityPlaceholder = HistoryCellModel(
        id: UUID(),
        kind: .personality,
        createdAt: "2026-05-19T12:00:00Z",
        selectedTests: [PersonalityTestTypes.astrology.rawValue, PersonalityTestTypes.attachmentStyle.rawValue],
        archetypeTitle: PersonalityResultModel.mock.archetypeTitle,
        archetypeSubtitle: PersonalityResultModel.mock.archetypeSubtitle,
        zodiacSign: PersonalityResultModel.mock.zodiacSign,
        compatibilityScore: nil,
        partnerName: nil,
        partnerZodiacSign: nil,
        personalityResult: nil,
        compatibilityResult: nil
    )

    static let compatibilityPlaceholder = HistoryCellModel(
        id: UUID(),
        kind: .compatibility,
        createdAt: "2026-05-19T12:00:00Z",
        selectedTests: [CompatibilityTestTypes.behavioralPatterns.rawValue],
        archetypeTitle: CompatibilityResultModel.mock.title,
        archetypeSubtitle: PersonalityResultModel.mock.archetypeSubtitle,
        zodiacSign: PersonalityResultModel.mock.zodiacSign,
        compatibilityScore: CompatibilityResultModel.mock.compatibilityScore,
        partnerName: CompatibilityResultModel.mock.partnerName,
        partnerZodiacSign: CompatibilityResultModel.mock.partnerZodiacSign,
        personalityResult: nil,
        compatibilityResult: CompatibilityResultModel.mock
    )
}

extension HistoryCellModel {
    var iconHandler: String {
        switch kind {
            case .personality:
                zodiacSign.icon
            case .compatibility:
                partnerZodiacSign?.icon ?? "👤"
        }
    }

    var titleText: String {
        switch kind {
            case .personality:
                archetypeTitle
            case .compatibility:
                partnerName ?? ""
        }
    }

    var dateText: String {
        guard let date = try? Date(createdAt, strategy: .iso8601) else { return "" }

        return date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "ru_RU")))
    }

    var compatibilityScoreText: String {
        "\(compatibilityScore ?? 0)%"
    }
}
