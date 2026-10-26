//
//  SignInStepView.swift
//  Aura
//
//  Created by ddorsat on 27.10.2026.
//

import SwiftUI

struct SignInStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(title: "С возвращением",
                             subtitle: "Войдите в свой аккаунт")

            VStack(alignment: .trailing, spacing: 10) {
                OnboardingTextField(type: .email, text: $vm.email)
                OnboardingTextField(type: .password, text: $vm.password)

                OnboardingTextButton(title: "Забыли пароль?") {
                    vm.showPasswordReset()
                }
            }

            ClassicButton(title: vm.isLoading ? "Входим..." : "Войти") {
                vm.signIn()
            }

            Spacer()

            VStack(spacing: 15) {
                OnboardingDivider()
                OnboardingAppleButton(vm: vm)

                HStack(spacing: 4) {
                    Text("Нет аккаунта?")
                        .font(Adaptive.size(.footnote, .callout))
                        .foregroundStyle(.deepGray)

                    OnboardingTextButton(title: "Создать") {
                        vm.showSignUp()
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
