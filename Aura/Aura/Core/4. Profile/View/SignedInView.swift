//
//  SignedInView.swift
//  Aura
//
//  Created by ddorsat on 06.05.2026.
//

import SwiftUI

struct SignedInView: View {
    @ObservedObject var vm: ProfileViewModel
    let user: UserModel

    var body: some View {
        ZStack {
            Components.backgroundColor()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .center, spacing: 10) {
                        Text(user.name.prefix(2).uppercased())
                            .font(.title)
                            .foregroundStyle(.white)
                            .fontWeight(.heavy)
                            .padding(25)
                            .background(LinearGradient(colors: [.purple,
                                                                .pink.opacity(0.7)],
                                                       startPoint: .top,
                                                       endPoint: .bottom))
                            .clipShape(Circle())

                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            Text(user.dateOfBirth.formatted())
                            
                            Text("·")
                                .font(.title3)
                                .bold()
                            
                            Text("Козерог")
                        }
                        .font(.callout)
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .backgroundWithShape(15, true)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("СОВЕТ ДНЯ")
                            .fontWeight(.heavy)

                        Text("""
                             "Работа, которую вы выполняете, тяжелая. Луна находится в транзите, что говорит о том, что сейчас время для внутреннего размышления, а не для внешних завоеваний"
                             """)
                        .font(.callout)
                        .italic()
                        .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.deepBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Лучшая совместимость")
                                .foregroundStyle(.deepGray)
                            
                            HStack(spacing: 10) {
                                Text("♑️")
                                    .font(.title2)
                                    .padding(10)
                                    .background(Circle() .stroke(Color(.systemGray6), lineWidth: 5))
                                    .background(LinearGradient(colors: [.softPurple,                                            .lightPurple],
                                                               startPoint: .top,
                                                               endPoint: .bottom))
                                    .clipShape(Circle())
                                
                                Text("Мария")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("91%")
                                    .font(.title2)
                                    .foregroundStyle(.deepBlue)
                                    .bold()
                            }
                        }
                        .padding(20)
                        .backgroundWithShape(15, true)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("О вас")
                                .bold()
                            
                            Text("Интуитивный креатор. Глубокий интроверт с мощной интуицией, который ищет настоящую связь, а не светскую болтовню.")
                                .font(.callout)
                                .foregroundStyle(.deepGray)
                            
                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.socialFilter, description: "Обладает встроенным детектором на пустую болтовню.")
                                
                                Divider()
                                
                                TestResultCellView(test: PersonalityCellTypes.emotionalDepth, description: "Обладает встроенным детектором на пустую болтовню.")
                            }
                            .testTopicsModifier()
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(15, true)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ваш психотип")
                                .bold()
                            
                            VStack(spacing: 15) {
                                Components.emotionalProfileBar(.temperament, 5)
                                Components.emotionalProfileBar(.thinking, 7)
                                Components.emotionalProfileBar(.organization, 3)
                                Components.emotionalProfileBar(.relationships, 6)
                            }
                            .padding(.top, 5)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(15, true)
                    }
                    .blur(radius: !vm.isProfileCompleted ? 5 : 0)
                    .overlay {
                        if !vm.isProfileCompleted {
                            Components.completeYourProfileLock("Пройдите тесты для получения результатов о себе")
                                .padding(.bottom, 500)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .scrollDisabled(!vm.isProfileCompleted)
            .scrollIndicators(.hidden)
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .bottomAreaPadding()
        }
    }
}

extension SignedInView {
    private func headerText(_ title: String) -> some View {
        Text(title)
            .fontWeight(.semibold)
            .padding(.leading, 4)
    }
}

#Preview {
    NavigationStack {
        SignedInView(vm: ProfileViewModel(), user: .mock)
    }
}
