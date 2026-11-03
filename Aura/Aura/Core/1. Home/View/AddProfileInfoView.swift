//
//  AddProfileInfoView.swift
//  Aura
//
//  Created by wamhrm on 06.05.2026.
//

import SwiftUI
import UIKit

struct AddProfileInfoView: View {
    @ObservedObject var vm: ProfileFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    ProfileInfoSection(title: "Ваше имя") {
                        CompatibilityTextFieldView(title: "Введите имя",
                                                   text: $vm.name,
                                                   type: .name())
                    }

                    ProfileInfoSection(title: "Ваш пол") {
                        HStack {
                            ProfileInfoOptionView(type: .man,
                                                  selection: $vm.profileInfo.gender)
                            ProfileInfoOptionView(type: .woman,
                                                  selection: $vm.profileInfo.gender)
                        }
                    }

                    ProfileInfoSection(title: "Дата рождения") {
                        BirthDateFieldsView(birthDate: $vm.birthDate,
                                            knowsBirthTime: $vm.knowsBirthTime,
                                            birthTime: $vm.birthTime,
                                            dateRange: BirthDateFormatter.userDateRange)
                    }

                    PsychotypeSectionsView(profileInfo: $vm.profileInfo)

                    ClassicButton(title: vm.saveButtonTitle) {
                        vm.saveProfileInfo {
                            dismiss()
                        }
                    }
                    .padding(.top, 5)
                    .disabled(vm.isLoading)
                }
                .disabled(vm.isLoading)
                .padding(.horizontal)
            }
            .bottomAreaPadding(50)
            .scrollIndicators(.hidden)
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("О вас")
        .navigationBarTitleDisplayMode(.inline)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) { }
        }
    }
}

enum ProfileInfoOption: String, CaseIterable {
    case man, woman, introvert, ambivert, extrovert, mediator, direct, avoider, logic, intuitive, planner, spontaneous, procrastinator, stability, growth, peace

    var title: String {
        switch self {
            case .man: "Мужской"
            case .woman: "Женский"
            case .introvert: "Интроверт"
            case .ambivert: "Амбиверт"
            case .extrovert: "Экстраверт"
            case .mediator: "Миротворец"
            case .direct: "Прямой"
            case .avoider: "Избегающий"
            case .logic: "Рациональный"
            case .intuitive: "Интуитивный"
            case .planner: "Планируете"
            case .spontaneous: "По ситуации"
            case .procrastinator: "Откладываете"
            case .stability: "Стабильность"
            case .growth: "Рост"
            case .peace: "Спокойствие"
        }
    }

    var icon: String {
        switch self {
            case .man: "👱🏻‍♂️"
            case .woman: "👩🏻"
            case .introvert: "🌙"
            case .ambivert: "🌗"
            case .extrovert: "🔥"
            case .mediator: "🤝"
            case .direct: "⚡"
            case .avoider: "🌫"
            case .logic: "🧠"
            case .intuitive: "✨"
            case .planner: "🗂"
            case .spontaneous: "⚡"
            case .procrastinator: "⏳"
            case .stability: "🛡"
            case .growth: "🚀"
            case .peace: "🕊"
        }
    }
}

#Preview {
    NavigationStack {
        AddProfileInfoView(vm: ProfileFormViewModel(authService: AuthService.preview,
                                                    user: .mock))
    }
}
