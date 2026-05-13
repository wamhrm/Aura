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
                            option("👱🏻‍♂️", "Мужской",
                                   AddProfileInfoCellType.Gender.man,
                                   $vm.profileInfo.gender)
                            option("👩🏻", "Женский",
                                   AddProfileInfoCellType.Gender.woman,
                                   $vm.profileInfo.gender)
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
                            option("🌙", "Интроверт",
                                   AddProfileInfoCellType.SocialType.introvert,
                                   $vm.profileInfo.socialType)
                            option("🌗", "Амбиверт",
                                   AddProfileInfoCellType.SocialType.ambivert,
                                   $vm.profileInfo.socialType)
                            option("🔥", "Экстраверт",
                                   AddProfileInfoCellType.SocialType.extrovert,
                                   $vm.profileInfo.socialType)
                        }
                    }
                    
                    section("Стиль в конфликте") {
                        FlowLayout() {
                            option("🤝", "Миротворец",
                                   AddProfileInfoCellType.ConflictStyle.mediator,
                                   $vm.profileInfo.conflictStyle)
                            option("⚡", "Прямой",
                                   AddProfileInfoCellType.ConflictStyle.direct,
                                   $vm.profileInfo.conflictStyle)
                            option("🌫", "Избегающий",
                                   AddProfileInfoCellType.ConflictStyle.avoider,
                                   $vm.profileInfo.conflictStyle)
                        }
                    }
                    
                    section("Эмоциональная основа") {
                        FlowLayout() {
                            option("🧠", "Рациональный",
                                   AddProfileInfoCellType.EmotionalCore.logic,
                                   $vm.profileInfo.emotionalCore)
                            option("✨", "Интуитивный",
                                   AddProfileInfoCellType.EmotionalCore.intuitive,
                                   $vm.profileInfo.emotionalCore)
                        }
                    }
                    
                    section("Вы чаще") {
                        FlowLayout() {
                            option("🗂", "Планируете",
                                   AddProfileInfoCellType.DecisionStyle.planner,
                                   $vm.profileInfo.decisionStyle)
                            option("⚡", "По ситуации",
                                   AddProfileInfoCellType.DecisionStyle.spontaneous,
                                   $vm.profileInfo.decisionStyle)
                            option("⏳", "Откладываете",
                                   AddProfileInfoCellType.DecisionStyle.procrastinator,
                                   $vm.profileInfo.decisionStyle)
                        }
                    }
                    
                    section("Приоритет") {
                        FlowLayout() {
                            option("🛡", "Стабильность",
                                   AddProfileInfoCellType.CoreRelationshipFocus.stability,
                                   $vm.profileInfo.coreFocus)
                            option("🚀", "Рост",
                                   AddProfileInfoCellType.CoreRelationshipFocus.growth,
                                   $vm.profileInfo.coreFocus)
                            option("🕊", "Спокойствие",
                                   AddProfileInfoCellType.CoreRelationshipFocus.peace,
                                   $vm.profileInfo.coreFocus)
                        }
                    }
                    
                    Button {
                        vm.saveProfileInfo()
                    } label: {
                        Text(vm.isSavingProfileInfo ? "Сохраняем..." : "Готово")
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
                    .disabled(vm.isSavingProfileInfo)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("О вас")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
        .alert("Не удалось сохранить профиль", isPresented: $vm.showProfileInfoError) {
            Button("ОК", role: .cancel) { }
        } message: {
            Text(vm.profileInfoErrorMessage ?? "Попробуйте еще раз")
        }
    }
}

extension AddProfileInfoView {
    private func option<T: Equatable>(_ emoji: String, _ title: String,
                                      _ value: T, _ selection: Binding<T?>) -> some View {
        let isSelected = selection.wrappedValue == value

        return HStack {
            Text(emoji)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .white : .black)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.deepBlue : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { selection.wrappedValue = value }
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

enum AddProfileInfoCellType {
    enum Gender: String, Codable {
        case man, woman
    }
    
    enum SocialType: String, Codable {
        case introvert, ambivert, extrovert
    }
    
    enum ConflictStyle: String, Codable {
        case mediator, direct, avoider
    }

    enum EmotionalCore: String, Codable {
        case logic, intuitive
    }
    
    enum DecisionStyle: String, CaseIterable, Codable {
        case planner, spontaneous, procrastinator
    }

    enum CoreRelationshipFocus: String, CaseIterable, Codable {
        case stability, growth, peace
    }
}

#Preview {
    NavigationStack {
        AddProfileInfoView(vm: HomeViewModel(authService: AuthService()))
    }
}
