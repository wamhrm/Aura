//
//  HistoryDTOs.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
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
    let personalityResult: PersonalityResultDTO?
    let compatibilityResult: CompatibilityResultDTO?
}

enum HistoryDTOMapper {
    private static func createdAtString(from date: Date?) -> String {
        guard let date else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func listItem(from history: History) throws -> HistoryItemDTO {
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
                                      personalityResult: nil,
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
                                      personalityResult: nil,
                                      compatibilityResult: result)
        }
    }

    static func detail(from history: History) throws -> HistoryItemDTO {
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
                                      personalityResult: result,
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
                                      personalityResult: nil,
                                      compatibilityResult: result)
        }
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
