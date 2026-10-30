//
//  NameAndBirthStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct NameAndBirthStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingHeader(title: vm.isSignedIn ? "Когда вы родились?" : "Как вас зовут и когда вы родились?",
                                 subtitle: "По дате рождения мы определим ваш знак зодиака")

                if !vm.isSignedIn {
                    OnboardingTextField(type: .name, text: $vm.name)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Дата рождения")
                        .font(Adaptive.size(.footnote, .callout))
                        .foregroundStyle(.deepGray)
                        .fontWeight(.semibold)

                    DatePicker("",
                               selection: $vm.birthDate,
                               in: OnboardingViewModel.birthDateRange,
                               displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(spacing: 15) {
                    Toggle("Я знаю время рождения", isOn: $vm.knowsBirthTime.animation())
                        .fontWeight(.semibold)
                        .tint(AccentColorOption.color(accentColor))

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
                .clipShape(RoundedRectangle(cornerRadius: 10))

                ClassicButton(title: "Далее") {
                    vm.continueFromNameAndBirth()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .environment(\.locale, Locale(identifier: "ru_RU"))
    }
}

#Preview {
    NameAndBirthStepView(vm: OnboardingViewModel(authService: AuthService(),
                                                 contentService: ContentService()) {})
}
