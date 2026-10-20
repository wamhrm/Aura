//
//  DateInputFormatter.swift
//  Aura
//
//  Created by ddorsat on 21.10.2026.
//

import Foundation

enum DateInputFormatter {
    enum Result: Equatable {
        case unchanged
        case formatted(String)
        case invalidBirthDate(trimmed: String)
    }

    static func format(_ input: String, isTime: Bool) -> Result {
        let formatted = isTime ? formattedTime(input) : formattedDate(input)

        if !isTime, formatted.count == 10, !isValidBirthDate(formatted) {
            return .invalidBirthDate(trimmed: String(input.dropLast(4)))
        }

        return formatted == input ? .unchanged : .formatted(formatted)
    }

    static func isValidBirthDate(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Int(parts[1]),
              let year = Int(parts[2]) else {
            return false
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: today)
        let minYear = currentYear - 100

        guard year >= minYear, year <= currentYear else { return false }

        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year

        guard let date = calendar.date(from: components),
              calendar.component(.day, from: date) == day,
              calendar.component(.month, from: date) == month,
              calendar.component(.year, from: date) == year else {
            return false
        }

        let birthDate = calendar.startOfDay(for: date)
        guard birthDate <= today else { return false }

        guard let earliestBirthDate = calendar.date(byAdding: .year, value: -100, to: today) else {
            return false
        }

        return birthDate >= calendar.startOfDay(for: earliestBirthDate)
    }

    private static func formattedTime(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let hours = digits.prefix(2)
        var formatted = String(hours)

        if digits.count > 2 {
            formatted += ":"
            formatted += digits.dropFirst(2).prefix(2)
        }
        if let h = Int(hours), h > 23 {
            formatted = "23" + (formatted.count > 2 ? formatted.dropFirst(2) : "")
        }
        if let m = Int(digits.dropFirst(2).prefix(2)), m > 59 {
            formatted = String(formatted.prefix(3)) + "59"
        }

        return String(formatted.prefix(5))
    }

    private static func formattedDate(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let day = digits.prefix(2)
        var formatted = String(day)

        if digits.count > 2 {
            formatted += "."
            formatted += digits.dropFirst(2).prefix(2)
        }
        if digits.count > 4 {
            formatted += "."
            formatted += digits.dropFirst(4).prefix(4)
        }
        if let d = Int(day), d > 31 {
            formatted = "31" + formatted.dropFirst(2)
        }
        if let m = Int(digits.dropFirst(2).prefix(2)), m > 12 {
            let dayStr = String(formatted.prefix(2))
            formatted = dayStr + ".12" + formatted.dropFirst(5)
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        if let y = Int(digits.dropFirst(4).prefix(4)), y > currentYear {
            let prefix = String(formatted.prefix(5))
            formatted = prefix + String(currentYear)
        }

        return String(formatted.prefix(10))
    }
}
