//
//  ResetPasswordStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct ResetPasswordStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack(alignment: .leading, spacing: 35) {
                if vm.isResetCodeSent {
                    OnboardingHeader(title: "Введите код из письма",
                                     subtitle: "Если аккаунт с почтой \(vm.email) есть, мы отправили на неё код. Он действует 15 минут.")

                    OnboardingTextField(text: $vm.resetCode, type: .code)
                    OnboardingTextField(text: $vm.newPassword, type: .newPassword)

                    ClassicButton(title: "Сохранить пароль") {
                        vm.resetPassword()
                    }

                    OnboardingTextButton(title: "Отправить код ещё раз") {
                        vm.requestPasswordReset()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    OnboardingHeader(title: "Сброс пароля",
                                     subtitle: "Введите почту аккаунта, и мы отправим на неё код для сброса пароля")

                    OnboardingTextField(text: $vm.email, type: .email)

                    ClassicButton(title: "Отправить код") {
                        vm.requestPasswordReset()
                    }
                }

                Spacer()
            }
            .onboardingViewModifier()
        }
    }
}

#Preview {
    ResetPasswordStepView(vm: OnboardingViewModel(authService: AuthService.preview))
}
