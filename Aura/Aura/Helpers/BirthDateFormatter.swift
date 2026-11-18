//
//  BirthDateFormatter.swift
//  Aura
//
//  Created by wamhrm on 03.11.2026.
//

import Foundation

enum BirthDateFormatter {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    static let defaultDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    static let defaultTime = calendar.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

    static var dateRange: ClosedRange<Date> {
        let calendar = Self.calendar
        let today = calendar.startOfDay(for: Date())
        let earliest = calendar.date(byAdding: DateComponents(year: -InputLimits.maxUserAge - 1, day: 1), to: today) ?? today
        let latest = calendar.date(byAdding: .year, value: -InputLimits.minUserAge, to: today) ?? today
        return earliest...latest
    }

    static func isAdult(date: Date) -> Bool {
        let calendar = Self.calendar
        let today = calendar.startOfDay(for: Date())
        guard let latest = calendar.date(byAdding: .year, value: -InputLimits.adultAge, to: today) else {
            return false
        }
        return calendar.startOfDay(for: date) <= latest
    }

    static func dateString(date: Date) -> String {
        formatter("dd.MM.yyyy").string(from: date)
    }

    static func timeString(date: Date) -> String {
        formatter("HH:mm").string(from: date)
    }

    static func date(string: String) -> Date? {
        formatter("dd.MM.yyyy").date(from: string)
    }

    static func time(string: String) -> Date? {
        formatter("HH:mm").date(from: string)
    }

    private static func formatter(_ dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = dateFormat
        return formatter
    }
}
