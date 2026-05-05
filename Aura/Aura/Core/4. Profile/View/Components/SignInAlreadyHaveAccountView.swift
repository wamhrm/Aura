//
//  SignInAlreadyHaveAccountView.swift
//  TravelBook
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct SignInAlreadyHaveAccountView: View {
    let type: SignInAlreadyHaveAccountType
    let onTapHandler: () -> Void
    
    var body: some View {
        Button(action: onTapHandler) {
            HStack {
                Spacer()
                
                Text(type.rawValue)
                    .foregroundStyle(.signInCreateAccountField)
                
                Button {
                    
                } label: {
                    Text(type.buttonTitle)
                        .foregroundStyle(.blue)
                        .bold()
                }
                
                Spacer()
            }
            .font(.callout)
        }
    }
}

enum SignInAlreadyHaveAccountType: String {
    case signIn = "Нет аккаунта?"
    case alreadyHaveAccount = "Уже есть аккаунт?"
    
    var buttonTitle: String {
        switch self {
            case .signIn: 
                return "Создать аккаунт"
            case .alreadyHaveAccount: 
                return "Войти"
        }
    }
}

#Preview {
    SignInAlreadyHaveAccountView(type: .signIn) {
        
    }
}
