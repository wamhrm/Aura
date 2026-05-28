//
//  SignInCreateAccountButtonView.swift
//  TravelBook
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct SignInCreateAccountButtonView: View {
    let type: SignInCreateAccountButtonTypes
    let isSignedOut: Bool
    let isLoading: Bool
    let onTapHandler: () -> Void
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue


    init(type: SignInCreateAccountButtonTypes,
         isSignedOut: Bool,
         isLoading: Bool = false,
         onTapHandler: @escaping () -> Void) {
        self.type = type
        self.isSignedOut = isSignedOut
        self.isLoading = isLoading
        self.onTapHandler = onTapHandler
    }
    
    var body: some View {
        Button(action: onTapHandler) {
            HStack(spacing: 15) {
                if type == .google {
                    Image("google")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 18, maxHeight: 18)
                        .padding(.leading, 4)
                        .clipped()
                } else if type == .apple {
                    Image(systemName: "apple.logo")
                        .foregroundStyle(.white)
                }
                
                Text(buttonTitle)
                    .font(Components.displaySize(.caption, .system(size: 14)))
                    .foregroundStyle(isSignedOut ? (type == .signIn ? .white : .black) : type.foregroundColor)
                    .padding(.leading, type == .apple ? 3 : 0)
            }
            .bold()
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSignedOut && type == .createAccount ? .white : buttonBackgroundColor)
            .overlay(RoundedRectangle(cornerRadius: 10) .stroke(.black, lineWidth: type == .google ? 0.3 : 0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

extension SignInCreateAccountButtonView {
    private var buttonTitle: String {
        return isLoading ? type.loadingTitle : type.rawValue
    }

    private var buttonBackgroundColor: Color {
        switch type {
            case .signIn, .createAccount:
                return Components.handleAccentColor(accentColor)
            case .apple:
                return .black
            case .google:
                return .white
        }
    }
}

enum SignInCreateAccountButtonTypes: String {
    case signIn = "Войти"
    case createAccount = "Создать аккаунт"
    case apple = "Apple"
    case google = "Google"

    var loadingTitle: String {
        switch self {
            case .signIn:
                return "Входим..."
            case .createAccount:
                return "Создаем аккаунт..."
            case .apple, .google:
                return rawValue
        }
    }
    
    var foregroundColor: Color {
        switch self {
            case .signIn, .createAccount, .apple:
                return .white
            case .google:
                return .black
        }
    }
}

#Preview {
    SignInCreateAccountButtonView(type: .google, isSignedOut: false, isLoading: false) {
        
    }
    .padding(.horizontal)
}
