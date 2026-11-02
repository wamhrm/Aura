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

    func fetchCurrentHoroscope(for user: User, req: Request, on database: any Database) async throws -> HoroscopeDTO {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            throw Abort(.notFound, reason: "Гороскоп не найден")
        }

        let week = DailyDateHelper.currentWeek(in: req.userTimeZone)

        if let entry = try await findHoroscope(sign: sign, weekStart: week.key, on: database) {
            return try HoroscopeDTOMapper.map(entry)
        }

        return try await SingleFlight.shared.run(key: "horoscope:\(sign.rawValue):\(week.key)") {
            // Another request may have finished generating while this one was on its way here
            if let entry = try await findHoroscope(sign: sign, weekStart: week.key, on: database) {
                return try HoroscopeDTOMapper.map(entry)
            }

            let generated = try await openAIService.makeHoroscope(for: sign,
                                                                  period: (week.start, week.end),
                                                                  req: req)

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
                      let existing = try await findHoroscope(sign: sign, weekStart: week.key, on: database) else {
                    throw error
                }
                return try HoroscopeDTOMapper.map(existing)
            }

            return try HoroscopeDTOMapper.map(entry)
        }
    }

    func findCurrentHoroscope(for user: User,
                              in timeZone: TimeZone,
                              on database: any Database) async throws -> HoroscopeDTO? {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            return nil
        }

        let week = DailyDateHelper.currentWeek(in: timeZone)
        let entry = try await findHoroscope(sign: sign, weekStart: week.key, on: database)
        return try entry.map(HoroscopeDTOMapper.map)
    }

    private func findHoroscope(sign: HoroscopeSign,
                               weekStart: String,
                               on database: any Database) async throws -> Horoscope? {
        try await Horoscope.query(on: database)
            .filter(\.$sign == sign.rawValue)
            .filter(\.$weekStart == weekStart)
            .first()
    }
}
