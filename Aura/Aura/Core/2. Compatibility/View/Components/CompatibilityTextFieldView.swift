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
    let type: CompatibilityTextFieldTypes

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .font(Adaptive.size(.footnote, .system(size: 14)))
                .foregroundStyle(.gray)
                .fontWeight(.medium)
                .frame(height: Adaptive.size(46, 48))
                .padding(.leading)
                .background(Color.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .keyboardType(keyboardType)
                .onChange(of: text) { _, newValue in
                    handleInputChange(newValue)
                }
        }
    }
}

extension CompatibilityTextFieldView {
    private var keyboardType: UIKeyboardType {
        switch type {
            case .age: .numberPad
            default: .default
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

enum CompatibilityTextFieldTypes {
    case name(maxLength: Int = 10)
    case age(maxAge: Int = 100)
}

#Preview {
    CompatibilityTextFieldView(title: "Введите имя", text: .constant(""), type: .age(maxAge: 20))
}
