//
//  SignInCreateAccountView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import AuthenticationServices
import SwiftUI

struct SignInCreateAccountView: View {
    @ObservedObject var vm: ProfileViewModel
    let type: SignInCreateAccountTypes

    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Text(type.rawValue)
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
            .dismissKeyboardOnTap()

            switch type {
                case .signIn:
                    VStack(spacing: 10) {
                        textFieldView(type: .email, field: $vm.email)
                        textFieldView(type: .password, field: $vm.password)
                        forgotPasswordButtonView()
                        SignInCreateAccountButtonView(vm: vm,
                                                      type: .signIn) {
                            vm.signIn()
                        }
                        .padding(.top, 5)
                    }
                    .dismissKeyboardOnTap()
                case .createAccount:
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
                    .dismissKeyboardOnTap()
                case .resetPassword:
                    resetPasswordView()
                        .dismissKeyboardOnTap()
            }

            if type != .resetPassword {
                HStack(spacing: 15) {
                    Rectangle()
                        .frame(height: 0.5)

                    Text("или")
                        .font(Adaptive.size(.callout, .system(size: 15)))

                    Rectangle()
                        .frame(height: 0.5)
                }
                .foregroundStyle(.gray)
                .dismissKeyboardOnTap()

                SignInWithAppleButton(.continue) { request in
                    vm.prepareAppleSignIn(request)
                } onCompletion: { result in
                    vm.completeAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            switch type {
                case .signIn:
                    alreadyHaveAccountButtonsView(type: .signIn) {
                        withAnimation {
                            vm.toggleSignInCreateView()
                        }
                    }
                case .createAccount:
                    alreadyHaveAccountButtonsView(type: .alreadyHaveAccount) {
                        withAnimation {
                            vm.toggleSignInCreateView()
                        }
                    }
                case .resetPassword:
                    alreadyHaveAccountButtonsView(type: .rememberedPassword) {
                        withAnimation {
                            vm.showSignInView()
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .padding(25)
        .background(RoundedRectangle(cornerRadius: 12).fill(.cardBackground).dismissKeyboardOnTap())
        .padding(.horizontal)
        .disabled(vm.isLoading)
        .scrollDismissesKeyboard(.interactively)
        .onDisappear {
            vm.clearTextFields()
            vm.dismissSignInCreateViews()
        }
    }
}

extension SignInCreateAccountView {
    private var cardHeight: CGFloat {
        switch type {
            case .signIn: Adaptive.size(440, 460)
            case .createAccount: Adaptive.size(490, 510)
            case .resetPassword: vm.isResetCodeSent ? Adaptive.size(430, 450) : Adaptive.size(300, 320)
        }
    }

    private func forgotPasswordButtonView() -> some View {
        Button {
            withAnimation {
                vm.showPasswordResetView()
            }
        } label: {
            Text("Забыли пароль?")
                .font(Adaptive.size(.footnote, .callout))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func resetPasswordView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(vm.isResetCodeSent
                 ? "Если аккаунт с почтой \(vm.email) есть, мы отправили на неё код. Он действует 15 минут."
                 : "Введите почту аккаунта, и мы отправим на неё код для сброса пароля.")
                .font(Adaptive.size(.footnote, .callout))
                .foregroundStyle(.signInCreateAccountField)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 5)

            if vm.isResetCodeSent {
                textFieldView(type: .code, field: $vm.resetCode)
                textFieldView(type: .newPassword, field: $vm.newPassword)
                SignInCreateAccountButtonView(vm: vm,
                                              type: .resetPassword) {
                    vm.resetPassword()
                }
                .padding(.top, 5)

                Button {
                    vm.requestPasswordReset()
                } label: {
                    Text("Отправить код ещё раз")
                        .font(Adaptive.size(.footnote, .callout))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 5)
            } else {
                textFieldView(type: .email, field: $vm.email)
                SignInCreateAccountButtonView(vm: vm,
                                              type: .sendCode) {
                    vm.requestPasswordReset()
                }
                .padding(.top, 5)
            }
        }
    }

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
                if type == .password || type == .newPassword {
                    SecureField(type.textField, text: field)
                        .textInputAutocapitalization(.never)
                } else {
                    TextField(type.textField, text: field)
                        .keyboardType(type.keyboardType)
                        .textContentType(type == .code ? .oneTimeCode : nil)
                        .textInputAutocapitalization(type == .name ? .words : .never)
                }
            }
            .font(Adaptive.size(.footnote, .callout))
            .frame(height: 48)
            .padding(.leading)
            .background(.signInCreateAccountFieldButton)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .autocorrectionDisabled(type != .name)
        }
    }
}

enum SignInCreateAccountTypes: String {
    case signIn = "Войти"
    case createAccount = "Создать аккаунт"
    case resetPassword = "Сброс пароля"
}

fileprivate enum AlreadyHaveAccountButtonTypes: String {
    case signIn = "Нет аккаунта?"
    case alreadyHaveAccount = "Уже есть аккаунт?"
    case rememberedPassword = "Вспомнили пароль?"

    var buttonTitle: String {
        switch self {
            case .signIn: "Создать аккаунт"
            case .alreadyHaveAccount, .rememberedPassword: "Войти"
        }
    }
}

fileprivate enum TextFieldTypes: String {
    case name = "Имя"
    case email = "Почта"
    case password = "Пароль"
    case code = "Код из письма"
    case newPassword = "Новый пароль"

    var textField: String {
        switch self {
            case .name: "Введите ваше имя"
            case .email: "Введите вашу почту"
            case .password: "Введите ваш пароль"
            case .code: "Введите 6 цифр"
            case .newPassword: "Придумайте новый пароль"
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
            case .email: .emailAddress
            case .code: .numberPad
            case .name, .password, .newPassword: .default
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
