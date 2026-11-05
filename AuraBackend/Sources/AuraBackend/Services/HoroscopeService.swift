//
//  HoroscopeService.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct HoroscopeService {
    private static let singleFlight = SingleFlight<HoroscopeDTO>()
    private let openAIService = OpenAIService()

    func fetchCurrentHoroscope(user: User, req: Request, database: any Database) async throws -> HoroscopeDTO {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            throw Abort(.notFound, reason: "Гороскоп не найден")
        }

        let week = DailyDateHelper.currentWeek(timeZone: req.userTimeZone)

        if let entry = try await findHoroscope(sign: sign, weekStart: week.key, db: database) {
            return try HoroscopeDTOMapper.map(horoscope: entry)
        }

        return try await Self.singleFlight.run(key: "horoscope:\(sign.rawValue):\(week.key)") {
            // Another request may have finished generating while this one was on its way here
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

            do {
                try await entry.save(on: database)
            } catch {
                guard (error as? any DatabaseError)?.isConstraintFailure == true,
                      let existing = try await findHoroscope(sign: sign, weekStart: week.key, db: database) else {
                    throw error
                }
                return try HoroscopeDTOMapper.map(horoscope: existing)
            }

            return try HoroscopeDTOMapper.map(horoscope: entry)
        }
    }

    func findCurrentHoroscope(user: User,
                              timeZone: TimeZone,
                              database: any Database) async throws -> HoroscopeDTO? {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            return nil
        }

        let week = DailyDateHelper.currentWeek(timeZone: timeZone)
        let entry = try await findHoroscope(sign: sign, weekStart: week.key, db: database)
        return try entry.map(HoroscopeDTOMapper.map)
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
