//
//  UserDateFormatter.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Foundation

enum UserDateFormatter {
    static let maxAgeInYears = 100
    static let minAgeInYears = 16

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    static func date(from string: String) -> Date? {
        // DateFormatter rolls impossible dates over: 31.02.2000 would become 02.03.2000
        guard let date = formatter.date(from: string), formatter.string(from: date) == string else { return nil }
        return date
    }

    static func birthDate(from string: String) -> Date? {
        guard let date = date(from: string) else { return nil }

        let now = Date()

        guard let earliestDate = calendar.date(byAdding: .year, value: -maxAgeInYears, to: now),
              date >= earliestDate,
              date <= now else {
            return nil
        }

        return date
    }

    static func isOldEnough(_ birthDate: Date) -> Bool {
        guard let latestDate = calendar.date(byAdding: .year, value: -minAgeInYears, to: Date()) else {
            return false
        }

        return birthDate <= latestDate
    }

    static func isValidTime(_ string: String) -> Bool {
        let parts = string.split(separator: ":", omittingEmptySubsequences: false)

        guard parts.count == 2,
              parts.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }),
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else {
            return false
        }

        return (0...23).contains(hours) && (0...59).contains(minutes)
    }

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}
