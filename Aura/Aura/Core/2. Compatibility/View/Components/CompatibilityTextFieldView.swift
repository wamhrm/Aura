//
//  CompatibilityTextFieldView.swift
//  Aura
//
//  Created by ddorsat on 08.05.2026.
//

import SwiftUI

struct CompatibilityTextFieldView: View {
    let title: String
    @Binding var text: String
    let type: InputFieldType
    
    @State private var suggestions: [String] = []
    @State private var showSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .foregroundStyle(.gray)
                .fontWeight(.medium)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .keyboardType(keyboardType)
                .onChange(of: text) { _, newValue in
                    handleInputChange(newValue)
                }
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch type {
            case .age: return .numberPad
            default: return .default
        }
    }
    
    private func handleInputChange(_ newValue: String) {
        switch type {
            case .name(let max):
                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                text = String(filtered.prefix(max))
                
            case .age(let max):
                let filtered = newValue.filter { $0.isNumber }
            
                if let age = Int(filtered), age > max {
                    text = String(max)
                } else {
                    text = filtered
                }
        }
    }
}

enum InputFieldType {
    case name(maxLength: Int = 10)
    case age(maxAge: Int = 100)
}

#Preview {
    CompatibilityTextFieldView(title: "Введите имя", text: .constant(""), type: .name(maxLength: 10))
}
