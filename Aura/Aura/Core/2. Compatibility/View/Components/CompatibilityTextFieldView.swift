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
                .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
                .foregroundStyle(.gray)
                .fontWeight(.medium)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onChange(of: text) { _, newValue in
                    let capitalized = newValue.capitalized
                    if capitalized != newValue {
                        text = capitalized
                    }
                }
                .frame(height: Adaptive.size(46, 46, 48))
                .padding(.leading)
                .background(Color.fieldBackground)
                .clipShape(.rect(cornerRadius: 10))
        }
    }
}

#Preview {
    CompatibilityTextFieldView(title: "Введите имя", text: .constant(""))
}
