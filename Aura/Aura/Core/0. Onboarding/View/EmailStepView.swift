//
//  EmailStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct EmailStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 35) {
            OnboardingHeader(title: "Какой у вас адрес электронной почты, \(vm.displayName)?",
                             subtitle: "На неё придёт код, если вы забудете пароль")

            OnboardingTextField(text: $vm.email, type: .email)
            
            Spacer()

            ClassicButton(title: vm.emailButtonTitle) {
                vm.continueFromEmail()
            }
            
            OnboardingLegalText()
        }
        .onboardingViewModifier()
    }
}

#Preview {
    NavigationStack {
        EmailStepView(vm: OnboardingViewModel(authService: AuthService.preview))
    }
}
