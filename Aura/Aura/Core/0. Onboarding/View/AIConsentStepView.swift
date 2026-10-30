//
//  AIConsentStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct AIConsentStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 15) {
            AIConsentContentView()
                .padding(.horizontal)

            ClassicButton(title: vm.isLoading ? "Сохраняем..." : "Разрешить") {
                vm.chooseAIConsent(true)
            }
            .padding(.horizontal)

            OnboardingTextButton(title: "Не сейчас") {
                vm.chooseAIConsent(false)
            }
            .padding(.bottom, 10)
        }
    }
}

#Preview {
    AIConsentStepView(vm: OnboardingViewModel(authService: AuthService(),
                                              contentService: ContentService()) {})
}
