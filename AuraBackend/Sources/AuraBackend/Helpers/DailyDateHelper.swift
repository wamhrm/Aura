//
//  DailyDateHelper.swift
//  AuraServer
//
//  Created by ddorsat on 26.05.2026.
//

import Foundation

enum DailyDateHelper {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private static let storageFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func todayString() -> String {
        return storageFormatter.string(from: Date())
    }

    static func isToday(_ generatedDate: String) -> Bool {
        return generatedDate == todayString()
    }
}
