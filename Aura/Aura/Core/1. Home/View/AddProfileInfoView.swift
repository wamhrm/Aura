//
//  AddProfileInfoView.swift
//  Aura
//
//  Created by ddorsat on 06.05.2026.
//

import SwiftUI

struct AddProfileInfoView: View {
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        ZStack {
            Components.backgroundColor()

            ScrollView {
                VStack(spacing: 16) {
                    section("Ваш пол") {
                        HStack {
                            option(.man, $vm.profileInfo.gender)
                            option(.woman, $vm.profileInfo.gender)
                        }
                    }

                    section("Дата рождения") {
                        VStack(spacing: 10) {
                            CompatibilityDateOfBirthView(title: "День/Месяц/Год",
                                                         text: $vm.profileInfo.dateOfBirth,
                                                         isTime: false)

                            CompatibilityDateOfBirthView(title: "Время (необязательно)",
                                                         text: $vm.profileInfo.birthTime,
                                                         isTime: true)
                        }
                    }

                    section("Темперамент") {
                        FlowLayout() {
                            option(.introvert, $vm.profileInfo.socialType)
                            option(.ambivert, $vm.profileInfo.socialType)
                            option(.extrovert, $vm.profileInfo.socialType)
                        }
                    }

                    section("Стиль в конфликте") {
                        FlowLayout() {
                            option(.mediator, $vm.profileInfo.conflictStyle)
                            option(.direct, $vm.profileInfo.conflictStyle)
                            option(.avoider, $vm.profileInfo.conflictStyle)
                        }
                    }

                    section("Эмоциональная основа") {
                        FlowLayout() {
                            option(.logic, $vm.profileInfo.emotionalCore)
                            option(.intuitive, $vm.profileInfo.emotionalCore)
                        }
                    }

                    section("Вы чаще") {
                        FlowLayout() {
                            option(.planner, $vm.profileInfo.decisionStyle)
                            option(.spontaneous, $vm.profileInfo.decisionStyle)
                            option(.procrastinator, $vm.profileInfo.decisionStyle)
                        }
                    }

                    section("Приоритет") {
                        FlowLayout() {
                            option(.stability, $vm.profileInfo.coreFocus)
                            option(.growth, $vm.profileInfo.coreFocus)
                            option(.peace, $vm.profileInfo.coreFocus)
                        }
                    }

                    Button {
                        vm.saveProfileInfo()
                    } label: {
                        Text(vm.isLoading ? "Сохраняем..." : "Готово")
                            .foregroundStyle(.white)
                            .bold()
                            .padding(15)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [Color(red: 0.42,
                                                                      green: 0.27,
                                                                      blue: 0.93),
                                                                Color(red: 0.62,
                                                                      green: 0.33,
                                                                      blue: 0.95)],
                                                       startPoint: .leading,
                                                       endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 5)
                    .disabled(vm.isLoading)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("О вас")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
        .alert(vm.errorMessage, isPresented: $vm.showError) {
            Button("ОК", role: .cancel) { }
        }
    }
}

extension AddProfileInfoView {
    private func option(_ type: ProfileInfoOption, _ selection: Binding<String?>) -> some View {
        let isSelected = selection.wrappedValue == type.rawValue

        return HStack {
            Text(type.icon)

            Text(type.rawValue)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .white : .black)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.deepBlue : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { selection.wrappedValue = type.rawValue }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(15, false)
    }
}

enum ProfileInfoOption: String {
    case man = "Мужской"
    case woman = "Женский"
    case introvert = "Интроверт"
    case ambivert = "Амбиверт"
    case extrovert = "Экстраверт"
    case mediator = "Миротворец"
    case direct = "Прямой"
    case avoider = "Избегающий"
    case logic = "Рациональный"
    case intuitive = "Интуитивный"
    case planner = "Планируете"
    case spontaneous = "По ситуации"
    case procrastinator = "Откладываете"
    case stability = "Стабильность"
    case growth = "Рост"
    case peace = "Спокойствие"
    
    var icon: String {
        switch self {
            case .man: return "👱🏻‍♂️"
            case .woman: return "👩🏻"
            case .introvert: return "🌙"
            case .ambivert: return "🌗"
            case .extrovert: return "🔥"
            case .mediator: return "🤝"
            case .direct: return "⚡"
            case .avoider: return "🌫"
            case .logic: return "🧠"
            case .intuitive: return "✨"
            case .planner: return "🗂"
            case .spontaneous: return "⚡"
            case .procrastinator: return "⏳"
            case .stability: return "🛡"
            case .growth: return "🚀"
            case .peace: return "🕊"
        }
    }
}

#Preview {
    NavigationStack {
        AddProfileInfoView(vm: HomeViewModel(authService: AuthService(), personalityService: PersonalityService()))
    }
}
