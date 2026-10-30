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
    static func getHistoryItem(from history: History) throws -> HistoryItemDTO {
        try makeHistoryItem(from: history, includeResult: false)
    }

    static func getHistoryItemDetails(from history: History) throws -> HistoryItemDTO {
        try makeHistoryItem(from: history, includeResult: true)
    }

    private static func makeHistoryItem(from history: History, includeResult: Bool) throws -> HistoryItemDTO {
        switch history.kind {
            case .personality:
                let result = try decodePersonalityResult(from: history.result)

                return HistoryItemDTO(id: try history.requireID(),
                                      kind: history.kind,
                                      createdAt: createdAtString(from: history.createdAt),
                                      selectedTests: history.selectedTests,
                                      archetypeTitle: result.archetypeTitle,
                                      archetypeSubtitle: result.archetypeSubtitle,
                                      zodiacSign: result.zodiacSign,
                                      compatibilityScore: nil,
                                      partnerName: nil,
                                      partnerZodiacSign: nil,
                                      personalityResult: includeResult ? result : nil,
                                      compatibilityResult: nil)
            case .compatibility:
                let result = try decodeCompatibilityResult(from: history.result)

                return HistoryItemDTO(id: try history.requireID(),
                                      kind: history.kind,
                                      createdAt: createdAtString(from: history.createdAt),
                                      selectedTests: history.selectedTests,
                                      archetypeTitle: result.title,
                                      archetypeSubtitle: result.subtitle,
                                      zodiacSign: result.userZodiacSign,
                                      compatibilityScore: result.compatibilityScore,
                                      partnerName: result.partnerName,
                                      partnerZodiacSign: result.partnerZodiacSign,
                                      personalityResult: nil,
                                      compatibilityResult: includeResult ? result : nil)
        }
    }

    private static func createdAtString(from date: Date?) -> String {
        guard let date else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private static func decodePersonalityResult(from resultJSON: String) throws -> PersonalityResultDTO {
        guard let data = resultJSON.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Некорректная запись истории")
        }

        return try JSONDecoder().decode(PersonalityResultDTO.self, from: data)
    }

    private static func decodeCompatibilityResult(from resultJSON: String) throws -> CompatibilityResultDTO {
        guard let data = resultJSON.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Некорректная запись истории")
        }

        return try JSONDecoder().decode(CompatibilityResultDTO.self, from: data)
    }
}
