//
//  PasswordStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct PasswordStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(title: "Придумайте пароль",
                             subtitle: "Не меньше \(InputLimits.minPasswordLength) символов")

            OnboardingTextField(text: $vm.password, type: .password)

            ClassicButton(title: vm.createAccountButtonTitle) {
                vm.createAccount()
            }

            Spacer()

            OnboardingLegalText()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview {
    PasswordStepView(vm: OnboardingViewModel(authService: AuthService.preview,
                                             contentService: ContentService.preview) {})
}
