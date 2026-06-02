//
//  DailyContentDTOs.swift
//  AuraBackend
//
//  Created by ddorsat on 26.05.2026.
//

import Vapor

struct DailyContentDTO: Content {
    let id: UUID
    let text: String
    let dateCreated: String
}

struct DailyContentResult: Codable {
    let text: String
}

enum DailyContentDTOMapper {
    static func map(_ entry: DailyContent) throws -> DailyContentDTO {
        guard let id = entry.id else {
            throw Abort(.internalServerError, reason: "Контент дня без идентификатора")
        }

        return DailyContentDTO(id: id,
                               text: entry.text,
                               dateCreated: entry.generatedDate)
    }
}
