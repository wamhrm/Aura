//
//  SignInCreateAccountButtonView.swift
//  TravelBook
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct SignInCreateAccountButtonView: View {
    @ObservedObject var vm: ProfileViewModel
    let type: SignInCreateAccountButtonTypes
    let onTapHandler: () -> Void
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    init(vm: ProfileViewModel,
         type: SignInCreateAccountButtonTypes,
         onTapHandler: @escaping () -> Void) {
        self.vm = vm
        self.type = type
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
                    .font(Adaptive.size(.caption, .system(size: 14)))
                    .foregroundStyle(vm.isSignedOut ? (type == .signIn ? .white : .black) : type.foregroundColor)
                    .padding(.leading, type == .apple ? 3 : 0)
            }
            .bold()
            .padding()
            .frame(maxWidth: .infinity)
            .background(vm.isSignedOut && type == .createAccount ? .white : buttonBackgroundColor)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

extension SignInCreateAccountButtonView {
    private var buttonTitle: String {
        vm.isLoading ? type.loadingTitle : type.rawValue
    }

    private var buttonBackgroundColor: Color {
        switch type {
            case .signIn, .createAccount: AccentColorOption.color(accentColor)
            case .apple: .black
            case .google: .white
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
            case .signIn: "Входим..."
            case .createAccount: "Создаем аккаунт..."
            case .apple, .google: rawValue
        }
    }
    
    var foregroundColor: Color {
        switch self {
            case .signIn, .createAccount, .apple: .white
            case .google: .black
        }
    }
}

#Preview {
    let authService = AuthService()
    let contentService = ContentService()
    SignInCreateAccountButtonView(vm: ProfileViewModel(authService: authService,
                                                       contentService: contentService),
                                  type: .google) {
        
    }
    .padding(.horizontal)
}
