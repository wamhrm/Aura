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
    
    var body: some View {
        TextField(title, text: $text)
            .foregroundStyle(.gray)
            .fontWeight(.medium)
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .keyboardType(.numberPad)
            .onChange(of: text, { _, newValue in
                formatInput(newValue)
            })
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
            if let y = Int(digits.dropFirst(4).prefix(4)), y > 2026 {
                let prefix = String(formatted.prefix(5))
                formatted = prefix + "2026"
            }
        }
        
        if isTime {
            if formatted.count > 5 { formatted = String(formatted.prefix(5)) }
        } else {
            if formatted.count > 10 { formatted = String(formatted.prefix(10)) }
        }
        
        if formatted != newValue {
            text = formatted
        }
    }
}

#Preview {
    CompatibilityDateOfBirthView(title: "123", text: .constant(""))
}
