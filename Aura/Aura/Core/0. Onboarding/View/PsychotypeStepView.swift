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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    OnboardingHeader(title: "Расскажите о себе",
                                     subtitle: "Ответы помогут точнее составить ваш психологический профиль")

                    ProfileInfoSection(title: "Ваш пол") {
                        HStack {
                            ProfileInfoOptionView(type: .man, selection: $vm.profileInfo.gender)
                            ProfileInfoOptionView(type: .woman, selection: $vm.profileInfo.gender)
                        }
                    }

                    PsychotypeSectionsView(profileInfo: $vm.profileInfo)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .scrollIndicators(.hidden)

            ClassicButton(title: "Далее") {
                vm.continueFromPsychotype()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
