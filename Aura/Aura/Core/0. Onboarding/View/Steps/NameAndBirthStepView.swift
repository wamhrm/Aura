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
                                     subtitle: "По дате рождения мы определим ваш знак зодиака")

                    if !vm.isSignedIn {
                        OnboardingTextField(text: $vm.name, type: .name)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дата рождения")
                            .font(Adaptive.size(.footnote, .callout))
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
                        Toggle("Я знаю время рождения", isOn: $vm.knowsBirthTime.animation())
                            .fontWeight(.semibold)

                        if vm.knowsBirthTime {
                            Divider()

                            DatePicker("Время рождения",
                                       selection: $vm.birthTime,
                                       displayedComponents: .hourAndMinute)
                        }
                    }
                    .font(Adaptive.size(.footnote, .callout))
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: 10))

                    ClassicButton(title: "Далее") {
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
