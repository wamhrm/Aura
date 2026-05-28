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

    private var profileDisplay: ProfileDisplayModel {
        vm.profileDisplay ?? .placeholder
    }

    var body: some View {
        ZStack {
            Components.backgroundColor()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .center, spacing: 10) {
                        Text(user.name.prefix(2).uppercased())
                            .font(Components.isRegular(.title3, .title2))
                            .foregroundStyle(.white)
                            .fontWeight(.heavy)
                            .padding(22)
                            .background(LinearGradient(colors: [.purple,
                                                                .pink.opacity(0.7)],
                                                       startPoint: .top,
                                                       endPoint: .bottom))
                            .clipShape(Circle())

                        Text(user.nameCapitalized)
                            .font(Components.isRegular(.title3, .title2))
                            .fontWeight(.bold)

                        HStack(alignment: .center, spacing: 5) {
                            Text(user.dateOfBirth ?? "Дата рождения не указана")

                            if let zodiacSign = profileDisplay.zodiacSignTitle {
                                Text("·")
                                    .font(.title3)
                                    .bold()

                                Text(zodiacSign)
                            }
                        }
                        .font(Components.isRegular(.footnote, .callout))
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .backgroundWithShape(12, .white, true)

                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("СОВЕТ ДНЯ")
                                .font(Components.isRegular(.callout, .default))
                                .fontWeight(.heavy)

                            Text(profileDisplay.dailyTip)
                                .font(Components.isRegular(.system(size: 14), .callout))
                                .fontWeight(.medium)
                                .italic()
                        }
                        .foregroundStyle(.white)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.deepBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Лучшая совместимость")
                                .font(Components.isRegular(.callout, .default))
                                .bold()

                            if let best = profileDisplay.bestCompatibility {
                                HStack(spacing: 10) {
                                    Text(best.partnerZodiacSign)
                                        .font(Components.isRegular(.system(size: 14), .callout))
                                        .padding(10)
                                        .background(Circle() .stroke(Color(.systemGray6), lineWidth: 5))
                                        .background(LinearGradient(colors: [.softPurple,                                     .lightPurple],
                                                                   startPoint: .top,
                                                                   endPoint: .bottom))
                                        .clipShape(Circle())

                                    Text(best.partnerName)
                                        .font(Components.isRegular(.system(size: 15), .system(size: 17)))
                                        .fontWeight(.semibold)

                                    Spacer()

                                    Text("\(best.score)%")
                                        .font(Components.isRegular(.system(size: 15), .system(size: 17)))
                                        .foregroundStyle(.deepBlue)
                                        .bold()
                                }
                            } else {
                                Text("Нет пройденных тестов на совместимость")
                                    .font(Components.isRegular(.system(size: 14), .callout))
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(12, .white, true)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("О вас")
                                .font(Components.isRegular(.callout, .default))
                                .bold()

                            Text(profileDisplay.overview)
                                .font(Components.isRegular(.footnote, .callout))
                                .foregroundStyle(.deepGray)

                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.socialFilter, description: profileDisplay.socialFilter)

                                Divider()

                                TestResultCellView(test: PersonalityCellTypes.emotionalDepth, description: profileDisplay.emotionalDepth)
                            }
                            .testTopicsModifier()
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(12, .white, true)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ваш психотип")
                                .font(Components.isRegular(.callout, .default))
                                .bold()

                            VStack(spacing: 15) {
                                Components.emotionalProfileBar(.temperament, profileDisplay.temperament)
                                Components.emotionalProfileBar(.thinking, profileDisplay.thinking)
                                Components.emotionalProfileBar(.organization, profileDisplay.organization)
                                Components.emotionalProfileBar(.relationships, profileDisplay.relationships)
                            }
                            .padding(.top, 5)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(12, .white, true)
                    }
                    .blur(radius: !vm.hasPersonalityTests ? 5 : 0)
                    .overlay {
                        if !vm.hasPersonalityTests {
                            Components.completeYourProfileLock("Пройдите тесты для получения результатов о себе")
                                .padding(.bottom, 500)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
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
        SignedInView(vm: ProfileViewModel(authService: AuthService(),
                                          contentService: ContentService()),
                     user: .mock)
    }
}
