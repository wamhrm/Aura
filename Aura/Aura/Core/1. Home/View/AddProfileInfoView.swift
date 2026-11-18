//
//  AddProfileInfoView.swift
//  Aura
//
//  Created by wamhrm on 06.05.2026.
//

import SwiftUI

struct AddProfileInfoView: View {
    @ObservedObject var vm: ProfileFormViewModel
    let onSave: () -> Void

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    ProfileInfoSection(title: AppLanguage.text("Ваше имя")) {
                        CompatibilityTextFieldView(title: AppLanguage.text("Введите имя"),
                                                   text: $vm.name)
                    }

                    ProfileInfoSection(title: AppLanguage.text("Ваш пол")) {
                        HStack {
                            ProfileInfoOptionView(type: .man,
                                                  selection: $vm.profileInfo.gender)
                            ProfileInfoOptionView(type: .woman,
                                                  selection: $vm.profileInfo.gender)
                        }
                    }

                    ProfileInfoSection(title: AppLanguage.text("Дата рождения")) {
                        BirthDateFieldsView(birthDate: $vm.birthDate,
                                            knowsBirthTime: $vm.knowsBirthTime,
                                            birthTime: $vm.birthTime,
                                            dateRange: BirthDateFormatter.dateRange)
                    }

                    PsychotypeSectionsView(profileInfo: $vm.profileInfo)

                    ClassicButton(title: AppLanguage.text("Готово")) {
                        onSave()
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal)
            }
            .bottomAreaPadding(50)
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(AppLanguage.text("О вас"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(vm.alertMessage, isPresented: vm.alertBinding) {
            Button(AppLanguage.text("ОК"), role: .cancel) { }
        }
    }
}

enum ProfileInfoOption: String, CaseIterable {
    case man, woman, introvert, ambivert, extrovert, mediator, direct, avoider, logic, intuitive, planner, spontaneous, procrastinator, stability, growth, peace

    var title: String {
        switch self {
            case .man: AppLanguage.text("Мужской")
            case .woman: AppLanguage.text("Женский")
            case .introvert: AppLanguage.text("Интроверт")
            case .ambivert: AppLanguage.text("Амбиверт")
            case .extrovert: AppLanguage.text("Экстраверт")
            case .mediator: AppLanguage.text("Миротворец")
            case .direct: AppLanguage.text("Прямой")
            case .avoider: AppLanguage.text("Избегающий")
            case .logic: AppLanguage.text("Рациональный")
            case .intuitive: AppLanguage.text("Интуитивный")
            case .planner: AppLanguage.text("Планируете")
            case .spontaneous: AppLanguage.text("По ситуации")
            case .procrastinator: AppLanguage.text("Откладываете")
            case .stability: AppLanguage.text("Стабильность")
            case .growth: AppLanguage.text("Рост")
            case .peace: AppLanguage.text("Спокойствие")
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
        AddProfileInfoView(vm: ProfileFormViewModel(user: .mock), onSave: {})
    }
}
