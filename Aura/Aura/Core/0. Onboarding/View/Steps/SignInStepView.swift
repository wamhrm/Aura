//
//  SignInStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct SignInStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack(alignment: .leading, spacing: 35) {
                OnboardingHeader(title: AppLanguage.text("С возвращением"),
                                 subtitle: AppLanguage.text("Войдите в свой аккаунт"))

                VStack(alignment: .trailing, spacing: 10) {
                    OnboardingTextField(text: $vm.email, type: .email)
                    OnboardingTextField(text: $vm.password, type: .password)

                    OnboardingTextButton(title: AppLanguage.text("Забыли пароль?")) {
                        vm.showPasswordReset()
                    }
                }

                ClassicButton(title: AppLanguage.text("Войти")) {
                    vm.signIn()
                }

                Spacer()

                VStack(spacing: 15) {
                    OnboardingLegalText()

                    HStack(spacing: 4) {
                        Text(AppLanguage.text("Нет аккаунта?"))
                            .font(Adaptive.size(.footnote, .system(size: 14), .callout))
                            .foregroundStyle(.deepGray)

                        OnboardingTextButton(title: AppLanguage.text("Создать")) {
                            vm.showSignUp()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    SignInStepView(vm: OnboardingViewModel(authService: AuthService.preview()))
}
