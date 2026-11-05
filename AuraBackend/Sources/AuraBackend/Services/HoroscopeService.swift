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

    func fetchCurrentHoroscope(_ user: User, _ req: Request, _ database: any Database) async throws -> HoroscopeDTO {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth) else {
            throw Abort(.notFound, reason: "Гороскоп не найден")
        }

        let week = DailyDateHelper.currentWeek(timeZone: req.userTimeZone)

        if let entry = try await findHoroscope(sign: sign, weekStart: week.key, database) {
            return try HoroscopeDTOMapper.map(entry)
        }

        return try await Self.singleFlight.run(key: "horoscope:\(sign.rawValue):\(week.key)") {
            // Another request may have finished generating while this one was on its way here
            if let entry = try await findHoroscope(sign: sign, weekStart: week.key, database) {
                return try HoroscopeDTOMapper.map(entry)
            }

            let generated = try await openAIService.makeHoroscope(sign: sign,
                                                                  period: (week.start, week.end),
                                                                  req)

            let entry = Horoscope(sign: sign.rawValue,
                                  weekStart: week.key,
                                  dateStart: week.start,
                                  dateEnd: week.end,
                                  description: generated.description,
                                  itemsJSON: try HoroscopeDTOMapper.encodeItems(generated.items))

            do {
                try await entry.save(on: database)
            } catch {
                guard (error as? any DatabaseError)?.isConstraintFailure == true,
                      let existing = try await findHoroscope(sign: sign, weekStart: week.key, database) else {
                    throw error
                }
                return try HoroscopeDTOMapper.map(existing)
            }

            return try HoroscopeDTOMapper.map(entry)
        }
    }

    func findCurrentHoroscope(_ user: User,
                              timeZone: TimeZone,
                              _ database: any Database) async throws -> HoroscopeDTO? {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth) else {
            return nil
        }

        let week = DailyDateHelper.currentWeek(timeZone: timeZone)
        let entry = try await findHoroscope(sign: sign, weekStart: week.key, database)
        return try entry.map(HoroscopeDTOMapper.map)
    }

    private func findHoroscope(sign: HoroscopeSign,
                               weekStart: String,
                               _ database: any Database) async throws -> Horoscope? {
        try await Horoscope.query(on: database)
            .filter(\.$sign == sign.rawValue)
            .filter(\.$weekStart == weekStart)
            .first()
    }
}
