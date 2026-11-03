//
//  CompatibilityTextFieldView.swift
//  Aura
//
//  Created by wamhrm on 08.05.2026.
//

import SwiftUI

struct CompatibilityTextFieldView: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .font(Adaptive.size(.footnote, .system(size: 14)))
                .foregroundStyle(.gray)
                .fontWeight(.medium)
                .frame(height: Adaptive.size(46, 48))
                .padding(.leading)
                .background(Color.fieldBackground)
                .clipShape(.rect(cornerRadius: 10))
                .onChange(of: text) { _, newValue in
                    let filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0 == "-" }
                    text = String(filtered.prefix(InputLimits.maxNameLength))
                }
        }
    }
}

#Preview {
    CompatibilityTextFieldView(title: "Введите имя", text: .constant(""))
}
