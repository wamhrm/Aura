//
//  DailyContentDTOs.swift
//  AuraServer
//
//  Created by ddorsat on 26.05.2026.
//

import Vapor

struct DailyInsightDTO: Content {
    let id: UUID
    let text: String
    let dateCreated: String
}

struct DailyTipDTO: Content {
    let id: UUID
    let text: String
    let dateCreated: String
}

struct DailyContentResult: Codable {
    let text: String
}

enum DailyContentDTOMapper {
    static func mapInsight(_ entry: DailyContent) throws -> DailyInsightDTO {
        guard let id = entry.id else {
            throw Abort(.internalServerError, reason: "Инсайт дня без идентификатора")
        }

        return DailyInsightDTO(id: id,
                               text: entry.text,
                               dateCreated: entry.generatedDate)
    }

    static func mapTip(_ entry: DailyContent) throws -> DailyTipDTO {
        guard let id = entry.id else {
            throw Abort(.internalServerError, reason: "Совет дня без идентификатора")
        }

        return DailyTipDTO(id: id,
                           text: entry.text,
                           dateCreated: entry.generatedDate)
    }
}
