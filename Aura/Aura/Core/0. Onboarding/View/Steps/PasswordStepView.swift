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
        ZStack {
            BackgroundView()
            
            VStack(alignment: .leading, spacing: 35) {
                OnboardingHeader(title: "Придумайте пароль",
                                 subtitle: "Не меньше \(InputLimits.minPasswordLength) символов")

                OnboardingTextField(text: $vm.password, type: .password)
            
                Spacer()

                ClassicButton(title: "Далее") {
                    vm.continueFromPassword()
                }

                OnboardingLegalText()
            }
            .onboardingViewModifier()
        }
    }
}

#Preview {
    PasswordStepView(vm: OnboardingViewModel(authService: AuthService.preview))
}
