//
//  PsychotypeStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct PsychotypeStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ZStack {
            BackgroundView()
            
            ScrollView {
                VStack(spacing: 15) {
                    OnboardingHeader(title: "Расскажите о себе",
                                     subtitle: "Ответы помогут точнее составить ваш психологический профиль")

                    PsychotypeSectionsView(profileInfo: $vm.profileInfo)
                    
                ClassicButton(title: "Далее") {
                    vm.continueFromPsychotype()
                }
                    .padding(.top)
                }
                .onboardingViewModifier()
            }
        }
    }
}

#Preview {
    PsychotypeStepView(vm: OnboardingViewModel(authService: AuthService.preview))
}
