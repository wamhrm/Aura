//
//  CompatibilityDateOfBirthView.swift
//  Aura
//
//  Created by ddorsat on 08.05.2026.
//

import SwiftUI

struct CompatibilityDateOfBirthView: View {
    let title: String
    @Binding var text: String
    var isTime: Bool = false
    var onInvalidDateOfBirth: (() -> Void)?
    
    var body: some View {
        TextField(title, text: $text)
            .font(Components.displaySize(.footnote, .system(size: 14)))
            .foregroundStyle(.gray)
            .fontWeight(.medium)
            .frame(height: Components.displaySize(46, 48))
            .padding(.leading)
            .background(Color.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .keyboardType(.numberPad)
            .onChange(of: text) { _, newValue in
                formatInput(newValue)
            }
    }
}

extension CompatibilityDateOfBirthView {
    private func formatInput(_ newValue: String) {
        let digits = newValue.filter { $0.isNumber }
        var formatted = ""
        
        if isTime {
            let hours = digits.prefix(2)
            formatted += hours
            
            if digits.count > 2 {
                formatted += ":"
                let minutes = digits.dropFirst(2).prefix(2)
                formatted += minutes
            }
            if let h = Int(hours), h > 23 {
                formatted = "23" + (formatted.count > 2 ? formatted.dropFirst(2) : "")
            }
            if let m = Int(digits.dropFirst(2).prefix(2)), m > 59 {
                formatted = String(formatted.prefix(3)) + "59"
            }
        } else {
            let day = digits.prefix(2)
            formatted += day
            
            if digits.count > 2 {
                formatted += "."
                let month = digits.dropFirst(2).prefix(2)
                formatted += month
            }
            if digits.count > 4 {
                formatted += "."
                let year = digits.dropFirst(4).prefix(4)
                formatted += year
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
        }

        if isTime {
            if formatted.count > 5 { formatted = String(formatted.prefix(5)) }
        } else {
            if formatted.count > 10 { formatted = String(formatted.prefix(10)) }
        }

        if !isTime, formatted.count == 10, !Self.isValidBirthDate(formatted) {
            text.removeLast(4)
            onInvalidDateOfBirth?()
            return
        }

        if formatted != newValue {
            text = formatted
        }
    }

    private static func isValidBirthDate(_ value: String) -> Bool {
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
}

#Preview {
    CompatibilityDateOfBirthView(title: "123", text: .constant(""))
        .padding(.horizontal)
}
