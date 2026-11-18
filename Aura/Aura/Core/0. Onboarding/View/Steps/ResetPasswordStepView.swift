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
                if vm.showsResetCodeEntry {
                    OnboardingHeader(title: AppLanguage.text("Введите код из письма"),
                                     subtitle: AppLanguage.text("Код для \(vm.email) действует 15 минут после отправки."))

                    OnboardingTextField(text: $vm.resetCode, type: .code)
                    OnboardingTextField(text: $vm.newPassword, type: .newPassword)

                    ClassicButton(title: AppLanguage.text("Сохранить пароль")) {
                        vm.resetPassword()
                    }

                    OnboardingTextButton(title: AppLanguage.text("Отправить код ещё раз")) {
                        vm.requestPasswordReset()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    OnboardingHeader(title: AppLanguage.text("Сброс пароля"),
                                     subtitle: AppLanguage.text("Введите почту аккаунта, и мы отправим на неё код для сброса пароля"))

                    OnboardingTextField(text: $vm.email, type: .email)

                    ClassicButton(title: AppLanguage.text("Отправить код")) {
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
    ResetPasswordStepView(vm: OnboardingViewModel(authService: AuthService.preview()))
}
