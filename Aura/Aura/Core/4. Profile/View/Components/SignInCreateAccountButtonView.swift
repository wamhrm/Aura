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
    let isLanding: Bool
    let onTapHandler: () -> Void
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    init(vm: ProfileViewModel,
         type: SignInCreateAccountButtonTypes,
         isLanding: Bool = false,
         onTapHandler: @escaping () -> Void) {
        self.vm = vm
        self.type = type
        self.isLanding = isLanding
        self.onTapHandler = onTapHandler
    }

    var body: some View {
        Button(action: onTapHandler) {
            Text(buttonTitle)
                .font(Adaptive.size(.caption, .system(size: 14)))
                .foregroundStyle(buttonForegroundColor)
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(buttonBackgroundColor)
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
            case .signIn: AccentColorOption.color(accentColor)
            case .createAccount: isLanding ? .white : AccentColorOption.color(accentColor)
        }
    }

    private var buttonForegroundColor: Color {
        switch type {
            case .signIn: .white
            case .createAccount: isLanding ? .black : .white
        }
    }
}

enum SignInCreateAccountButtonTypes: String {
    case signIn = "Войти"
    case createAccount = "Создать аккаунт"

    var loadingTitle: String {
        switch self {
            case .signIn: "Входим..."
            case .createAccount: "Создаем аккаунт..."
        }
    }
}

#Preview {
    let authService = AuthService()
    let contentService = ContentService()
    SignInCreateAccountButtonView(vm: ProfileViewModel(authService: authService,
                                                       contentService: contentService),
                                  type: .signIn) {
        
    }
    .padding(.horizontal)
}
