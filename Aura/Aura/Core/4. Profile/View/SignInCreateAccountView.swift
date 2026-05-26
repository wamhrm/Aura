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
    @Binding var showSignInCreate: Bool
    var onTapHandler: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Text(type == .signIn ? "Войти" : "Создать аккаунт")
                    .font(Components.isRegular(.title3, .title2))
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    withAnimation(.easeIn(duration: 0.25)) {
                        showSignInCreate.toggle()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(Components.isRegular(.callout, .default))
                        .fontWeight(.medium)
                        .foregroundStyle(.deepBlue)
                        .padding(Components.isRegular(8, 10))
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }

            if type == .signIn {
                VStack(spacing: 10) {
                    SignInCreateAccountTextFieldView(type: .email, field: $vm.email)
                    SignInCreateAccountTextFieldView(type: .password, field: $vm.password)
                    SignInCreateAccountButtonView(type: .signIn,
                                                  isSignedOut: false,
                                                  isLoading: vm.isLoading) {
                        vm.signIn()
                    }
                    .padding(.top, 5)
                }
            } else {
                VStack(spacing: 10) {
                    SignInCreateAccountTextFieldView(type: .name, field: $vm.name)
                    SignInCreateAccountTextFieldView(type: .email, field: $vm.email)
                    SignInCreateAccountTextFieldView(type: .password, field: $vm.password)
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
                SignInCreateAccountButtonView(type: .google, isSignedOut: false) {

                }

                SignInCreateAccountButtonView(type: .apple, isSignedOut: false) {

                }
            }

            if type == .signIn {
                SignInAlreadyHaveAccountView(type: .signIn) {
                    onTapHandler()
                }
            } else {
                SignInAlreadyHaveAccountView(type: .alreadyHaveAccount) {
                    onTapHandler()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: type == .signIn ? Components.isRegular(470, 490) : Components.isRegular(550, 570))
        .padding(25)
        .background(RoundedRectangle(cornerRadius: 12) .fill(.white))
        .padding(.horizontal)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) { }
        }
        .onDisappear {
            vm.clearTextFields()
        }
    }
}

enum SignInCreateAccountType: String {
    case signIn = "Войти"
    case createAccount = "Создать аккаунт"
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
