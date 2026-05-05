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
                    section("👤", "Ваш пол") {
                        HStack {
                            option("👱🏻‍♂️", "Мужской",
                                   AddProfileInfoCellType.Gender.man,
                                   $vm.userSex)
                            option("👩🏻", "Женский",
                                   AddProfileInfoCellType.Gender.woman,
                                   $vm.userSex)
                        }
                    }
                    
                    section("🔋", "Социальная энергия") {
                        FlowLayout() {
                            option("🌙", "Интроверт",
                                   AddProfileInfoCellType.SocialType.introvert,
                                   $vm.socialType)
                            option("🌗", "Амбиверт",
                                   AddProfileInfoCellType.SocialType.ambivert,
                                   $vm.socialType)
                            option("🔥", "Экстраверт",
                                   AddProfileInfoCellType.SocialType.extrovert,
                                   $vm.socialType)
                        }
                    }
                    
                    section("⚔️", "Стиль в конфликте") {
                        FlowLayout() {
                            option("🤝", "Миротворец",
                                   AddProfileInfoCellType.ConflictStyle.mediator,
                                   $vm.conflictStyle)
                            option("⚡", "Прямой",
                                   AddProfileInfoCellType.ConflictStyle.direct,
                                   $vm.conflictStyle)
                            option("🌫", "Избегающий",
                                   AddProfileInfoCellType.ConflictStyle.avoider,
                                   $vm.conflictStyle)
                        }
                    }
                    
                    section("💫", "Эмоциональная основа") {
                        FlowLayout() {
                            option("🧠", "Рациональный",
                                   AddProfileInfoCellType.EmotionalCore.logic,
                                   $vm.emotionalCore)
                            option("✨", "Интуитивный",
                                   AddProfileInfoCellType.EmotionalCore.intuitive,
                                   $vm.emotionalCore)
                        }
                    }
                    
                    section("📊", "Вы чаще") {
                        FlowLayout() {
                            option("🗂", "Планируете",
                                   AddProfileInfoCellType.DecisionStyle.planner,
                                   $vm.decisionStyle)
                            option("⚡", "По ситуации",
                                   AddProfileInfoCellType.DecisionStyle.spontaneous,
                                   $vm.decisionStyle)
                            option("⏳", "Откладываете",
                                   AddProfileInfoCellType.DecisionStyle.procrastinator,
                                   $vm.decisionStyle)
                        }
                    }
                    
                    section("❤️", "Приоритет") {
                        FlowLayout() {
                            option("🛡", "Стабильность",
                                   AddProfileInfoCellType.CoreRelationshipFocus.stability,
                                   $vm.coreFocus)
                            option("🚀", "Рост",
                                   AddProfileInfoCellType.CoreRelationshipFocus.growth,
                                   $vm.coreFocus)
                            option("🕊", "Спокойствие",
                                   AddProfileInfoCellType.CoreRelationshipFocus.peace,
                                   $vm.coreFocus)
                        }
                    }
                    
                    Button {
                        
                    } label: {
                        Text("Готово")
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
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("О вас")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
    }
}

extension AddProfileInfoView {
    private func header(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
            
            Text(text)
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)
        }
    }
    
    private func option<T: Equatable>(_ emoji: String, _ title: String,
                                      _ value: T, _ selection: Binding<T?>) -> some View {
        let isSelected = selection.wrappedValue == value

        return HStack {
            Text(emoji)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .white : .black)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.softPurple : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { selection.wrappedValue = value }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    private func section<Content: View>(_ emoji: String, _ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            header(emoji, title)
            
            content()
        }
        .addProfileInfoSectionStyle()
    }
}

enum AddProfileInfoCellType {
    enum Gender: String {
        case man, woman
    }
    
    enum SocialType: String {
        case introvert, ambivert, extrovert
    }
    
    enum ConflictStyle: String {
        case mediator, direct, avoider
    }

    enum EmotionalCore: String {
        case logic, intuitive
    }
    
    enum DecisionStyle: String, CaseIterable {
        case planner, spontaneous, procrastinator
    }

    enum CoreRelationshipFocus: String, CaseIterable {
        case stability, growth, peace
    }
}

#Preview {
    NavigationStack {
        AddProfileInfoView(vm: HomeViewModel())
    }
}
