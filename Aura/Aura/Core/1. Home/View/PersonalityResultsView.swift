//
//  TestResultsView.swift
//  Aura
//
//  Created by ddorsat on 11.05.2026.
//

import SwiftUI

struct PersonalityResultsView: View {
    @ObservedObject var vm: HomeViewModel
    
    var body: some View {
        ZStack {
            Components.backgroundColor()
            
            if let result = vm.personalityResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack {
                            HStack(spacing: 15) {
                                Text(result.zodiacSign)
                                    .fontWeight(.semibold)
                                    .padding(10)
                                    .background(.lightPurple)
                                    .clipShape(Circle())
                                
                                Text(result.name)
                                    .font(.title2)
                                    .fontDesign(.monospaced)
                                    .bold()
                            }
                            .padding(.vertical, 20)
                            
                            VStack(alignment: .center, spacing: 15) {
                                HStack {
                                    ForEach(result.selectedTests, id: \.self) { test in
                                        Components.testCellImage(test.icon, test.color, .default, 30, true)
                                    }
                                }
                                
                                Text(result.archetypeTitle)
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                                
                                Text(result.archetypeSubtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.deepGray)
                                    .multilineTextAlignment(.center)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 10)
                        
                        section(result.overview.title) {
                            Text(result.overview.description)
                                .font(.callout)
                                .foregroundStyle(.deepGray)
                        }
                        
                        ForEach(result.sections, id: \.self) { test in
                            section(test.title) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("«Вдумчивый коммуникатор»")
                                        .fontWeight(.medium)
                                    
                                    Text("Вы предпочитаете глубокие разговоры поверхностному общению и выбираете слова с осторожностью")
                                        .foregroundStyle(.deepGray)
                                }
                                .font(.callout)
                            }
                        }
                        
                        section("Поведенческие паттерны") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("«Вдумчивый коммуникатор»")
                                    .fontWeight(.medium)
                                
                                Text("Вы предпочитаете глубокие разговоры поверхностному общению и выбираете слова с осторожностью")
                                    .foregroundStyle(.deepGray)
                            }
                            .font(.callout)
                            
                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.socialFilter, description: "Обладает встроенным детектором на пустую болтовню.")
                                
                                Divider()
                                
                                TestResultCellView(test: PersonalityCellTypes.energyDrain, description: "Обладает встроенным детектором на пустую болтовню.")
                            }
                            .testTopicsModifier()
                        }
                        
                        section("Внутренний мир") {
                            VStack(spacing: 15) {
                                Components.emotionalProfileBar(.temperament, 5)
                                Components.emotionalProfileBar(.thinking, 7)
                                Components.emotionalProfileBar(.organization, 3)
                                Components.emotionalProfileBar(.relationships, 6)
                            }
                            .padding(.top, 5)
                        }
                        
                        section("Стиль принятия решений") {
                            Text("Твой мозг — это биокомпьютер, который не терпит системных ошибок и случайных переменных.")
                                .font(.callout)
                                .foregroundStyle(.deepGray)
                            
                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.logicBalance, description: "Обладает встроенным детектором на пустую болтовню.")
                                
                                Divider()
                                
                                TestResultCellView(test: PersonalityCellTypes.intuitionFactor, description: "Обладает встроенным детектором на пустую болтовню.")
                            }
                            .testTopicsModifier()
                        }
                        
                        section("Стиль привязанности") {
                            Text("Отношения для тебя — это не клетка, а союз двух независимых государств с четкими границами.")
                                .font(.callout)
                                .foregroundStyle(.deepGray)
                            
                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.autonomyNeed, description: "Обладает встроенным детектором на пустую болтовню.")
                                
                                Divider()
                                
                                TestResultCellView(test: PersonalityCellTypes.securityBase, description: "Обладает встроенным детектором на пустую болтовню.")
                            }
                            .testTopicsModifier()
                        }
                        
                        section("Идеальный партнер") {
                            Text("Тебе не нужен просто человек рядом, тебе нужен союзник для захвата мира или хотя бы качественного молчания.")
                                .font(.callout)
                                .foregroundStyle(.deepGray)
                            
                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.intellectualMatch, description: "Обладает встроенным детектором на пустую болтовню.")
                                
                                Divider()
                                
                                TestResultCellView(test: PersonalityCellTypes.emotionalDepth, description: "Обладает встроенным детектором на пустую болтовню.")
                            }
                            .testTopicsModifier()
                        }
                        
                        section("Язык любви") {
                            Text("Ты выражаешь чувства на своем диалекте и ждешь, что партнер не поленится купить словарь.")
                                .font(.callout)
                                .foregroundStyle(.deepGray)
                            
                            VStack {
                                TestResultCellView(test: CompatibilityCellTypes.languageMatch, description: "Обладает встроенным детектором на пустую болтовню.")
                                
                                Divider()
                                
                                TestResultCellView(test: CompatibilityCellTypes.translationNeeds, description: "Обладает встроенным детектором на пустую болтовню.")
                            }
                            .testTopicsModifier()
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                ContentUnavailableView {
                    Text("Результат пока недоступен")
                }
            }
        }
        .navigationTitle("Результаты теста")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
    }
}

extension PersonalityResultsView {
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .bold()
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(15, true)
    }
}

#Preview {
    NavigationStack {
        PersonalityResultsView(vm: HomeViewModel(authService: AuthService(),
                                                 personalityService: PersonalityService()))
    }
}
