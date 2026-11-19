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
        ZStack {
            BackgroundView()
            
            VStack(alignment: .leading, spacing: 35) {
                OnboardingHeader(title: "Какой у вас адрес электронной почты, \(vm.displayName)?",
                                 subtitle: "На неё придёт код, если вы забудете пароль")

                OnboardingTextField(text: $vm.email, type: .email)
                
                Spacer()

                ClassicButton(title: vm.emailButtonTitle) {
                    vm.continueFromEmail()
                }
                .disabled(vm.isCheckingEmail)
                .animation(.easeInOut(duration: 0.2), value: vm.isCheckingEmail)
                
                OnboardingLegalText()
            }
            .onboardingViewModifier()
        }
    }
}

#Preview {
    NavigationStack {
        EmailStepView(vm: OnboardingViewModel(authService: AuthService.preview()))
    }
}
