//
//  CompatibilityDateOfBirthView.swift
//  Aura
//
//  Created by wamhrm on 08.05.2026.
//

import SwiftUI

struct CompatibilityDateOfBirthView: View {
    let title: String
    @Binding var text: String
    var isTime = false
    var onInvalidDateOfBirth: (() -> Void)?
    
    var body: some View {
        TextField(title, text: $text)
            .font(Adaptive.size(.footnote, .system(size: 14)))
            .foregroundStyle(.gray)
            .fontWeight(.medium)
            .frame(height: Adaptive.size(46, 48))
            .padding(.leading)
            .background(Color.fieldBackground)
            .clipShape(.rect(cornerRadius: 10))
            .keyboardType(.numberPad)
            .onChange(of: text) { _, newValue in
                switch DateInputFormatter.format(newValue, isTime: isTime) {
                    case .unchanged:
                        break
                    case .formatted(let formatted):
                        text = formatted
                    case .invalidBirthDate(let trimmed):
                        text = trimmed
                        onInvalidDateOfBirth?()
                }
            }
    }
}

#Preview {
    CompatibilityDateOfBirthView(title: "123", text: .constant(""))
        .padding(.horizontal)
}
