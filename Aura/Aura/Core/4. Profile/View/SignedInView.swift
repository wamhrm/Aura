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
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    private var profileDisplay: ProfileDisplayModel {
        return vm.profileDisplay ?? .placeholder
    }

    var body: some View {
        ZStack {
            Components.backgroundColor()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .center, spacing: 10) {
                        Text(user.name.prefix(2).uppercased())
                            .font(Components.displaySize(.title3, .title2))
                            .foregroundStyle(.white)
                            .fontWeight(.heavy)
                            .padding(22)
                            .background(LinearGradient(colors: [.purple,
                                                                .pink.opacity(0.7)],
                                                       startPoint: .top,
                                                       endPoint: .bottom))
                            .clipShape(Circle())

                        Text(user.nameCapitalized)
                            .font(Components.displaySize(.title3, .title2))
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
                        .font(Components.displaySize(.footnote, .system(size: 15)))
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .backgroundWithShape(12, .cardBackground, true)

                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("СОВЕТ ДНЯ")
                                .font(Components.displaySize(.callout, .default))
                                .fontWeight(.heavy)

                            Text(profileDisplay.dailyTip)
                                .font(.system(size: Components.displaySize(14, 15))).italic()
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Components.handleAccentColor(accentColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let best = profileDisplay.bestCompatibility {
                            VStack(alignment: .leading, spacing: Components.displaySize(16, 17)) {
                                Text("Лучшая совместимость")
                                    .font(Components.displaySize(.system(size: 15), .default))
                                    .bold()


                                HStack(spacing: 15) {
                                    Text(!best.partnerZodiacSign.isEmpty ? best.partnerZodiacSign : "👤")
                                        .zodiacSingModifier()

                                    Text(best.partnerName)
                                        .font(Components.displaySize(.callout, .default))
                                        .bold()

                                    Spacer()

                                    Text("\(best.score)%")
                                        .font(Components.displaySize(.callout, .default))
                                        .foregroundStyle(Components.handleAccentColor(accentColor))
                                        .bold()
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .backgroundWithShape(12, .cardBackground, true)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("О вас")
                                .font(Components.displaySize(.system(size: 15), .default))
                                .bold()

                            Text(profileDisplay.overview)
                                .font(.system(size: Components.displaySize(14, 15)))
                                .foregroundStyle(.deepGray)

                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.socialFilter,
                                                   description: profileDisplay.socialFilter)

                                Divider()

                                TestResultCellView(test: PersonalityCellTypes.emotionalDepth,
                                                   description: profileDisplay.emotionalDepth)
                            }
                            .testTopicsModifier()
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(12, .cardBackground, true)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ваш психотип")
                                .font(Components.displaySize(.system(size: 15), .default))
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
                        .backgroundWithShape(12, .cardBackground, true)
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
                .bottomAreaPadding(15)
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
