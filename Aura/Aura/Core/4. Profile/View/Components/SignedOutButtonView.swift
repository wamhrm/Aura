//
//  SignedOutButtonView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SignedOutButtonView: View {
    let type: SignedOutButtonTypes
    let onTapHandler: () -> Void
    
    var body: some View {
        Button(action: onTapHandler) {
            VStack {
                Text(type.rawValue)
                    .foregroundStyle(type == .signIn ? .deepBlue : .black)
                    .bold()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .backgroundWithShape(10, true)
        }
    }
}

enum SignedOutButtonTypes: String {
    case signIn = "Войти"
    case createAccout = "Создать аккаунт"
}

#Preview {
    SignedOutButtonView(type: .signIn) {
        
    }
}
