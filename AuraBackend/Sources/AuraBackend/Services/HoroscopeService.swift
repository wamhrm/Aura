//
//  HoroscopeService.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct HoroscopeService {
    private let openAIService = OpenAIService()

    func makeHoroscopeTest(for user: User, req: Request, on database: any Database) async throws -> HoroscopeDTO {
        guard let dateOfBirth = user.dateOfBirth else {
            throw Abort(.badRequest, reason: "Укажите дату рождения")
        }

        guard let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            throw Abort(.badRequest, reason: "Не удалось определить знак зодиака")
        }

        let userID = try user.requireID()
        let generated = try await openAIService.makeHoroscopeTest(for: sign, req: req)
        let period = openAIService.horoscopePeriod()

        try await Horoscope.query(on: database)
            .filter(\.$user.$id == userID)
            .delete()

        let itemsJSON = try HoroscopeDTOMapper.encodeItems(generated.items)

        let entry = Horoscope(userID: userID,
                              sign: sign.rawValue,
                              dateStart: period.start,
                              dateEnd: period.end,
                              description: generated.description,
                              itemsJSON: itemsJSON)

        try await entry.save(on: database)

        return try HoroscopeDTOMapper.map(entry)
    }

    func getCurrentHoroscopeTest(for user: User, on database: any Database) async throws -> HoroscopeDTO {
        let userID = try user.requireID()

        guard let entry = try await Horoscope.query(on: database)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .first()
        else {
            throw Abort(.notFound, reason: "Гороскоп не найден")
        }

        return try HoroscopeDTOMapper.map(entry)
    }
}
