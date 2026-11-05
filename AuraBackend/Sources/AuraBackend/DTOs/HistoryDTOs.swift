//
//  HistoryDTOs.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Foundation
import Vapor

struct HistoryItemDTO: Content {
    let id: UUID
    let kind: TestKind
    let createdAt: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let zodiacSign: String
    let compatibilityScore: Int?
    let partnerName: String?
    let partnerZodiacSign: String?
    let personalityResult: PersonalityResultDTO?
    let compatibilityResult: CompatibilityResultDTO?
}

enum HistoryDTOMapper {
    static func getHistoryItem(_ history: History) throws -> HistoryItemDTO {
        try makeHistoryItem(history: history, personalityResult: nil, compatibilityResult: nil)
    }

    static func getHistoryItemDetails(_ history: History) throws -> HistoryItemDTO {
        switch history.kind {
            case .personality:
                return try makeHistoryItem(history: history,
                                           personalityResult: try decodePersonalityResult(history.result),
                                           compatibilityResult: nil)
            case .compatibility:
                return try makeHistoryItem(history: history,
                                           personalityResult: nil,
                                           compatibilityResult: try decodeCompatibilityResult(history.result))
        }
    }

    private static func makeHistoryItem(history: History,
                                        personalityResult: PersonalityResultDTO?,
                                        compatibilityResult: CompatibilityResultDTO?) throws -> HistoryItemDTO {
        HistoryItemDTO(id: try history.requireID(),
                       kind: history.kind,
                       createdAt: createdAtString(history.createdAt),
                       selectedTests: history.selectedTests,
                       archetypeTitle: history.title,
                       archetypeSubtitle: history.subtitle,
                       zodiacSign: history.zodiacSign,
                       compatibilityScore: history.compatibilityScore,
                       partnerName: history.partnerName,
                       partnerZodiacSign: history.partnerZodiacSign,
                       personalityResult: personalityResult,
                       compatibilityResult: compatibilityResult)
    }

    private static func createdAtString(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func decodePersonalityResult(_ resultJSON: String) throws -> PersonalityResultDTO {
        let data = Data(resultJSON.utf8)
        return try JSONDecoder().decode(PersonalityResultDTO.self, from: data)
    }

    static func decodeCompatibilityResult(_ resultJSON: String) throws -> CompatibilityResultDTO {
        let data = Data(resultJSON.utf8)
        return try JSONDecoder().decode(CompatibilityResultDTO.self, from: data)
    }
}
