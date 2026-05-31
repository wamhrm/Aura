//
//  SignInCreateAccountView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SignInCreateAccountView: View {
    @ObservedObject var vm: ProfileViewModel
    let type: SignInCreateAccountType

    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Text(type == .signIn ? "Войти" : "Создать аккаунт")
                    .font(Adaptive.size(.title3, .title2))
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        vm.dismissSignInCreateViews()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(Adaptive.size(.callout, .default))
                        .fontWeight(.medium)
                        .foregroundStyle(AccentColorOption.color(accentColor))
                        .padding(Adaptive.size(8, 10))
                        .background(Color.fieldBackground)
                        .clipShape(Circle())
                }
            }

            if type == .signIn {
                VStack(spacing: 10) {
                    textFieldView(type: .email, field: $vm.email)
                    textFieldView(type: .password, field: $vm.password)
                    SignInCreateAccountButtonView(vm: vm,
                                                  type: .signIn) {
                        vm.signIn()
                    }
                    .padding(.top, 5)
                }
            } else {
                VStack(spacing: 10) {
                    textFieldView(type: .name, field: $vm.name)
                    textFieldView(type: .email, field: $vm.email)
                    textFieldView(type: .password, field: $vm.password)
                    SignInCreateAccountButtonView(vm: vm,
                                                  type: .createAccount) {
                        vm.createAccount()
                    }
                    .padding(.top, 5)
                }
            }

            HStack(spacing: 15) {
                Rectangle()
                    .frame(height: 0.5)

                Text("или")
                    .font(Adaptive.size(.callout, .system(size: 15)))

                Rectangle()
                    .frame(height: 0.5)
            }
            .foregroundStyle(.gray)

            VStack(spacing: 10) {
                SignInCreateAccountButtonView(vm: vm, type: .google) {}
                SignInCreateAccountButtonView(vm: vm, type: .apple) {}
            }

            if type == .signIn {
                alreadyHaveAccountButtonsView(type: .signIn) {
                    withAnimation {
                        vm.switchAuthMode()
                    }
                }
            } else {
                alreadyHaveAccountButtonsView(type: .alreadyHaveAccount) {
                    withAnimation {
                        vm.switchAuthMode()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: type == .signIn ? Adaptive.size(470, 490) : Adaptive.size(550, 570))
        .padding(25)
        .background(RoundedRectangle(cornerRadius: 12).fill(.cardBackground))
        .padding(.horizontal)
        .disabled(vm.isLoading)
        .dismissKeyboardOnTap()
        .scrollDismissesKeyboard(.interactively)
        .onDisappear {
            vm.clearTextFields()
            vm.dismissSignInCreateViews()
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
            .font(Adaptive.size(.footnote, .callout))
        }
    }

    private func textFieldView(type: TextFieldTypes,
                               field: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Adaptive.size(5, 6)) {
            Text(type.rawValue)
                .font(Adaptive.size(.footnote, .callout))
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
            .font(Adaptive.size(.footnote, .callout))
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
            case .signIn: "Создать аккаунт"
            case .alreadyHaveAccount: "Войти"
        }
    }
}

fileprivate enum TextFieldTypes: String {
    case name = "Имя"
    case email = "Почта"
    case password = "Пароль"

    var textField: String {
        switch self {
            case .name: "Введите ваше имя"
            case .email: "Введите вашу почту"
            case .password: "Введите ваш пароль"
        }
    }
}

#Preview {
    let authService = AuthService()
    let contentService = ContentService()

    SignInCreateAccountView(vm: ProfileViewModel(authService: authService,
                                                 contentService: contentService),
                            type: .createAccount)
}
