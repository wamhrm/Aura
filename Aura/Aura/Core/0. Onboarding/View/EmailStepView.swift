//
//  EmailStepView.swift
//  Aura
//
//  Created by ddorsat on 27.10.2026.
//

import SwiftUI

struct EmailStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(title: "Какая у вас почта, \(vm.displayName)?",
                             subtitle: "На неё придёт код, если вы забудете пароль")

            OnboardingTextField(type: .email, text: $vm.email)

            ClassicButton(title: "Далее") {
                vm.continueFromEmail()
            }

            Spacer()

            VStack(spacing: 15) {
                OnboardingDivider()
                OnboardingAppleButton(vm: vm)
                OnboardingLegalText()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
