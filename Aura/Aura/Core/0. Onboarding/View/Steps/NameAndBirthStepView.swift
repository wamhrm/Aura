//
//  NameAndBirthStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct NameAndBirthStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ZStack {
            BackgroundView()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 35) {
                    OnboardingHeader(title: vm.nameAndBirthTitle,
                                     subtitle: AppLanguage.text("По дате рождения мы определим ваш знак зодиака"))

                    if !vm.isSignedIn {
                        OnboardingTextField(text: $vm.name, type: .name)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppLanguage.text("Дата рождения"))
                            .font(Adaptive.size(.footnote, .system(size: 14), .callout))
                            .foregroundStyle(.deepGray)
                            .fontWeight(.semibold)

                        DatePicker("",
                                   selection: $vm.birthDate,
                                   in: BirthDateFormatter.dateRange,
                                   displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(Color.cardBackground)
                            .clipShape(.rect(cornerRadius: 10))
                    }

                    VStack(spacing: 15) {
                        Toggle(AppLanguage.text("Я знаю время рождения"), isOn: $vm.knowsBirthTime.animation())
                            .fontWeight(.semibold)

                        if vm.knowsBirthTime {
                            Divider()

                            DatePicker(AppLanguage.text("Время рождения"),
                                       selection: $vm.birthTime,
                                       displayedComponents: .hourAndMinute)
                        }
                    }
                    .font(Adaptive.size(.footnote, .system(size: 14), .callout))
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: 10))

                    ClassicButton(title: AppLanguage.text("Далее")) {
                        vm.continueFromNameAndBirth()
                    }
                }
                .onboardingViewModifier()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    NameAndBirthStepView(vm: OnboardingViewModel(authService: AuthService.preview))
}
