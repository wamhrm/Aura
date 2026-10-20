//
//  HistoryCellModel.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import Foundation

struct HistoryCellModel: Codable, Identifiable, Hashable {
    let id: UUID
    let kind: HistoryTestKind
    let createdAt: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let zodiacSign: String
    let compatibilityScore: Int?
    let partnerName: String?
    let partnerZodiacSign: String?
    let personalityResult: PersonalityResultModel?
    let compatibilityResult: CompabilityResultModel?
}

enum HistoryTestKind: String, Codable, Hashable {
    case personality
    case compatibility
}

extension HistoryCellModel {
    static let personalityPlaceholder = HistoryCellModel(
        id: UUID(),
        kind: .personality,
        createdAt: "2026-05-19T12:00:00Z",
        selectedTests: ["Астрология", "Стиль привязанности"],
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
        selectedTests: ["Поведенческие паттерны"],
        archetypeTitle: CompabilityResultModel.mock.title,
        archetypeSubtitle: PersonalityResultModel.mock.archetypeSubtitle,
        zodiacSign: PersonalityResultModel.mock.zodiacSign,
        compatibilityScore: CompabilityResultModel.mock.compatibilityScore,
        partnerName: CompabilityResultModel.mock.partnerName,
        partnerZodiacSign: CompabilityResultModel.mock.partnerZodiacSign,
        personalityResult: nil,
        compatibilityResult: CompabilityResultModel.mock
    )
}

extension HistoryCellModel {
    var resolvedCompatibilityScore: Int? {
        compatibilityScore ?? compatibilityResult?.compatibilityScore
    }

    var resolvedPartnerName: String? {
        partnerName ?? compatibilityResult?.partnerName
    }

    var resolvedPartnerZodiacSign: String? {
        partnerZodiacSign ?? compatibilityResult?.partnerZodiacSign
    }
}
