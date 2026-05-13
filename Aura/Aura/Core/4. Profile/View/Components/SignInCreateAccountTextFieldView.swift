//
//  SignInCreateAccountFieldView.swift
//  TravelBook
//
//  Created by ddorsat on 03.05.2026.
//

import SwiftUI

struct SignInCreateAccountTextFieldView: View {
    let type: SignInCreateAccountTextFieldType
    @Binding var field: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(type.rawValue)
                .foregroundStyle(.signInCreateAccountField)
                .fontWeight(.semibold)
                
            Group {
                if type == .password {
                    SecureField(type.textField, text: $field)
                } else {
                    TextField(type.textField, text: $field)
                        .textInputAutocapitalization(type == .email ? .never : .words)
                        .keyboardType(type == .email ? .emailAddress : .default)
                }
            }
            .autocorrectionDisabled(type == .email || type == .password)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(.signInCreateAccountFieldButton)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }
}

enum SignInCreateAccountTextFieldType: String {
    case name = "Имя"
    case email = "Почта"
    case password = "Пароль"
    
    var textField: String {
        switch self {
            case .name:
                return "Введите ваше имя"
            case .email:
                return "Введите вашу почту"
            case .password:
                return "Введите ваш пароль"
        }
    }

}

#Preview {
    SignInCreateAccountTextFieldView(type: .email, field: .constant(""))
}
