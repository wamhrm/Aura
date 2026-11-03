//
//  BirthDateFormatter.swift
//  Aura
//
//  Created by wamhrm on 03.11.2026.
//

import Foundation

enum BirthDateFormatter {
    static let defaultDate = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    static let defaultTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

    static let userDateRange = dateRange(minAge: InputLimits.minUserAge, maxAge: InputLimits.maxUserAge)
    static let partnerDateRange = dateRange(minAge: InputLimits.minPartnerAge, maxAge: InputLimits.maxPartnerAge)

    static func dateString(from date: Date) -> String {
        formatter("dd.MM.yyyy").string(from: date)
    }

    static func timeString(from date: Date) -> String {
        formatter("HH:mm").string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter("dd.MM.yyyy").date(from: string)
    }

    static func time(from string: String) -> Date? {
        formatter("HH:mm").date(from: string)
    }

    // The extra day covers the time zone difference with the server
    private static func dateRange(minAge: Int, maxAge: Int) -> ClosedRange<Date> {
        let now = Date()
        let earliest = Calendar.current.date(byAdding: DateComponents(year: -maxAge, day: 1), to: now) ?? now
        let latest = Calendar.current.date(byAdding: DateComponents(year: -minAge, day: -1), to: now) ?? now
        return earliest...latest
    }

    private static func formatter(_ dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = dateFormat
        return formatter
    }
}
