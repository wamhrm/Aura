//
//  UserDateFormatter.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Foundation

enum UserDateFormatter {
    private static let maxAgeInYears = 100
    private static let minAgeInYears = 16
    private static let adultAgeInYears = 18

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
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

    static func date(string: String) -> Date? {
        guard let date = formatter.date(from: string), formatter.string(from: date) == string else { return nil }
        return date
    }

    static func today(timeZone: TimeZone) -> Date {
        let now = Date()
        var localCalendar = calendar
        localCalendar.timeZone = timeZone
        let components = localCalendar.dateComponents([.year, .month, .day], from: now)
        return calendar.date(from: components) ?? calendar.startOfDay(for: now)
    }

    static func birthDate(date: String, today: Date) -> Date? {
        guard let parsedDate = Self.date(string: date) else { return nil }

        guard let earliestDate = calendar.date(byAdding: DateComponents(year: -maxAgeInYears - 1, day: 1), to: today),
              parsedDate >= earliestDate,
              parsedDate <= today else {
            return nil
        }

        return parsedDate
    }

    static func isOldEnough(birthDate: Date, today: Date) -> Bool {
        guard let latestDate = calendar.date(byAdding: .year, value: -minAgeInYears, to: today) else {
            return false
        }

        return birthDate <= latestDate
    }

    static func isAdult(birthDate: Date, today: Date) -> Bool {
        guard let latestDate = calendar.date(byAdding: .year, value: -adultAgeInYears, to: today) else {
            return false
        }

        return birthDate <= latestDate
    }

    static func isValidTime(string: String) -> Bool {
        let parts = string.split(separator: ":", omittingEmptySubsequences: false)

        guard parts.count == 2,
              parts.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }),
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else {
            return false
        }

        return (0...23).contains(hours) && (0...59).contains(minutes)
    }

    static func string(date: Date) -> String {
        formatter.string(from: date)
    }
}
