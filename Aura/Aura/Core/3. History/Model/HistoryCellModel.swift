//
//  HistoryCellModel.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import Foundation

enum HistoryTestKind: String, Decodable, Hashable {
    case personality
    case compatibility
}

struct HistoryCellModel: Decodable, Identifiable, Hashable {
    let id: UUID
    let kind: HistoryTestKind
    let createdAt: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let zodiacSign: String
    let personalityResult: PersonalityResultModel?
    let compatibilityResult: CompabilityResultModel?
}
