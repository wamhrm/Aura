//
//  DailyDateHelper.swift
//  AuraBackend
//
//  Created by wamhrm on 26.05.2026.
//

import Foundation

enum DailyDateHelper {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private static let weekCalendar: Calendar = {
        var weekCalendar = calendar
        weekCalendar.firstWeekday = 2
        return weekCalendar
    }()

    private static let storageFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let periodFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    static func todayString() -> String {
        storageFormatter.string(from: Date())
    }

    static func currentWeek() -> (key: String, start: String, end: String) {
        let now = Date()
        let startDate = weekCalendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate

        return (storageFormatter.string(from: startDate),
                periodFormatter.string(from: startDate),
                periodFormatter.string(from: endDate))
    }

    static func isToday(_ generatedDate: String) -> Bool {
        generatedDate == todayString()
    }
}
