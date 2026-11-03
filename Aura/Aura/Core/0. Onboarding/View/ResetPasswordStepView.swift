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
        VStack(alignment: .leading, spacing: 20) {
            if vm.isResetCodeSent {
                OnboardingHeader(title: "Введите код из письма",
                                 subtitle: "Если аккаунт с почтой \(vm.email) есть, мы отправили на неё код. Он действует 15 минут.")

                OnboardingTextField(text: $vm.resetCode, type: .code)
                OnboardingTextField(text: $vm.newPassword, type: .newPassword)

                ClassicButton(title: vm.resetPasswordButtonTitle) {
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

                ClassicButton(title: vm.sendCodeButtonTitle) {
                    vm.requestPasswordReset()
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview {
    ResetPasswordStepView(vm: OnboardingViewModel(authService: AuthService.preview,
                                                  contentService: ContentService.preview) {})
}
