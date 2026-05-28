//
//  SignInCreateAccountView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SignInCreateAccountView: View {
    @ObservedObject var vm: ProfileViewModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    let type: SignInCreateAccountType
    @Binding var showSignInCreate: Bool
    private let onTapHandler: () -> Void

    init(vm: ProfileViewModel,
         type: SignInCreateAccountType,
         showSignInCreate: Binding<Bool>,
         onTapHandler: @escaping () -> Void) {
        self.vm = vm
        self.type = type
        self._showSignInCreate = showSignInCreate
        self.onTapHandler = onTapHandler
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Text(type == .signIn ? "Войти" : "Создать аккаунт")
                    .font(Components.displaySize(.title3, .title2))
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showSignInCreate.toggle()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(Components.displaySize(.callout, .default))
                        .fontWeight(.medium)
                        .foregroundStyle(Components.handleAccentColor(accentColor))
                        .padding(Components.displaySize(8, 10))
                        .background(Color.fieldBackground)
                        .clipShape(Circle())
                }
            }

            if type == .signIn {
                VStack(spacing: 10) {
                    textFieldView(type: .email, field: $vm.email)
                    textFieldView(type: .password, field: $vm.password)
                    SignInCreateAccountButtonView(type: .signIn,
                                                  isSignedOut: false,
                                                  isLoading: vm.isLoading) {
                        vm.signIn()
                    }
                    .padding(.top, 5)
                }
            } else {
                VStack(spacing: 10) {
                    textFieldView(type: .name, field: $vm.name)
                    textFieldView(type: .email, field: $vm.email)
                    textFieldView(type: .password, field: $vm.password)
                    SignInCreateAccountButtonView(type: .createAccount,
                                                  isSignedOut: false,
                                                  isLoading: vm.isLoading) {
                        vm.createAccount()
                    }
                    .padding(.top, 5)
                }
            }

            HStack(spacing: 15) {
                Rectangle()
                    .frame(height: 0.5)

                Text("или")

                Rectangle()
                    .frame(height: 0.5)
            }
            .foregroundStyle(.gray)

            VStack(spacing: 10) {
                SignInCreateAccountButtonView(type: .google, isSignedOut: false) {}
                SignInCreateAccountButtonView(type: .apple, isSignedOut: false) {}
            }

            if type == .signIn {
                alreadyHaveAccountButtonsView(type: .signIn) {
                    onTapHandler()
                }
            } else {
                alreadyHaveAccountButtonsView(type: .alreadyHaveAccount) {
                    onTapHandler()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: type == .signIn ? Components.displaySize(470, 490) : Components.displaySize(550, 570))
        .padding(25)
        .background(RoundedRectangle(cornerRadius: 12) .fill(.cardBackground))
        .padding(.horizontal)
        .disabled(vm.isLoading)
        .dismissKeyboardOnTap()
        .scrollDismissesKeyboard(.interactively)
        .onDisappear {
            vm.clearTextFields()
        }
    }
}

extension SignInCreateAccountView {
    private func alreadyHaveAccountButtonsView(type: AlreadyHaveAccountButtonTypes,
                                               onTapHandler: @escaping () -> Void) -> some View {
        Button(action: onTapHandler) {
            HStack {
                Spacer()

                Text(type.rawValue)
                    .foregroundStyle(.signInCreateAccountField)

                Text(type.buttonTitle)
                    .foregroundStyle(.blue)
                    .bold()

                Spacer()
            }
            .font(Components.displaySize(.footnote, .callout))
        }
    }

    private func textFieldView(type: TextFieldTypes,
                               field: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Components.displaySize(5, 6)) {
            Text(type.rawValue)
                .font(Components.displaySize(.footnote, .callout))
                .foregroundStyle(.signInCreateAccountField)
                .fontWeight(.semibold)

            Group {
                if type == .password {
                    SecureField(type.textField, text: field)
                        .textInputAutocapitalization(.never)
                } else {
                    TextField(type.textField, text: field)
                        .keyboardType(type == .email ? .emailAddress : .default)
                        .textInputAutocapitalization(type == .email ? .never : .words)
                }
            }
            .font(Components.displaySize(.footnote, .callout))
            .frame(height: 48)
            .padding(.leading)
            .background(.signInCreateAccountFieldButton)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .autocorrectionDisabled(type == .email || type == .password)
        }
    }
}

enum SignInCreateAccountType: String {
    case signIn = "Войти"
    case createAccount = "Создать аккаунт"
}

fileprivate enum AlreadyHaveAccountButtonTypes: String {
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

fileprivate enum TextFieldTypes: String {
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
    let authService = AuthService()
    let contentService = ContentService()

    SignInCreateAccountView(vm: ProfileViewModel(authService: authService,
                                                 contentService: contentService),
                            type: .createAccount,
                            showSignInCreate: .constant(false)) {

    }
}
