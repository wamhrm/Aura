//
//  DailyDateHelper.swift
//  AuraBackend
//
//  Created by wamhrm on 26.05.2026.
//

import Foundation
import Vapor

enum DailyDateHelper {
    static func todayString(timeZone: TimeZone, now: Date = Date()) -> String {
        storageFormatter(timeZone: timeZone).string(from: now)
    }

    static func currentWeek(timeZone: TimeZone, now: Date = Date()) -> (key: String, start: String, end: String) {
        let calendar = weekCalendar(timeZone: timeZone)
        let startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        let periodFormatter = periodFormatter(timeZone: timeZone)

        return (storageFormatter(timeZone: timeZone).string(from: startDate),
                periodFormatter.string(from: startDate),
                periodFormatter.string(from: endDate))
    }

    private static func weekCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return calendar
    }

    private static func storageFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = weekCalendar(timeZone: timeZone)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private static func periodFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = weekCalendar(timeZone: timeZone)
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMM"
        return formatter
    }
}

extension Request {
    // The day and the week follow the user's clock. A missing or unknown zone means UTC.
    var userTimeZone: TimeZone {
        headers.first(name: "X-Time-Zone").flatMap(TimeZone.init(identifier:)) ?? .gmt
    }
}
