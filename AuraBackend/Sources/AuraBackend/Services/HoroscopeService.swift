//
//  HoroscopeService.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct HoroscopeService {
    private let openAIService = OpenAIService()

    func fetchCurrentHoroscope(user: User, req: Request) async throws -> HoroscopeDTO {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            throw Abort(.notFound, reason: "Гороскоп не найден")
        }

        let week = DailyDateHelper.currentWeek(timeZone: req.userTimeZone)
        let database = req.db

        if let entry = try await findHoroscope(sign: sign, weekStart: week.key, db: database) {
            return try HoroscopeDTOMapper.map(horoscope: entry)
        }

        return try await database.generationLock("horoscope:\(sign.rawValue):\(week.key)") { database in
            if let entry = try await findHoroscope(sign: sign, weekStart: week.key, db: database) {
                return try HoroscopeDTOMapper.map(horoscope: entry)
            }

            let generated = try await openAIService.makeHoroscope(sign: sign,
                                                                  period: (week.start, week.end),
                                                                  req: req)

            let entry = Horoscope(sign: sign.rawValue,
                                  weekStart: week.key,
                                  dateStart: week.start,
                                  dateEnd: week.end,
                                  description: generated.description,
                                  itemsJSON: try HoroscopeDTOMapper.encodeItems(items: generated.items))

            try await entry.save(on: database)
            return try HoroscopeDTOMapper.map(horoscope: entry)
        }
    }

    private func findHoroscope(sign: HoroscopeSign,
                               weekStart: String,
                               db: any Database) async throws -> Horoscope? {
        try await Horoscope.query(on: db)
            .filter(\.$sign == sign.rawValue)
            .filter(\.$weekStart == weekStart)
            .first()
    }
}
