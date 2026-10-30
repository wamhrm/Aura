//
//  SignedInView.swift
//  Aura
//
//  Created by wamhrm on 06.05.2026.
//

import SwiftUI

struct SignedInView: View {
    @ObservedObject var vm: ProfileViewModel
    let user: UserModel
    let aiConsentButton: () -> Void
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .center, spacing: 10) {
                        Text(user.nameInitials)
                            .font(Adaptive.size(.title3, .title2))
                            .foregroundStyle(.white)
                            .fontWeight(.heavy)
                            .padding(22)
                            .background(LinearGradient(colors: [.purple,
                                                                .pink.opacity(0.7)],
                                                       startPoint: .top,
                                                       endPoint: .bottom))
                            .clipShape(.circle)

                        Text(user.nameCapitalized)
                            .font(Adaptive.size(.title3, .title2))
                            .fontWeight(.bold)

                        HStack(alignment: .center, spacing: 5) {
                            Text(user.dateOfBirthHandler)

                            if let zodiacSign = vm.profileDisplayHandler.zodiacSignTitle {
                                Text("·")
                                    .font(.title3)
                                    .bold()

                                Text(zodiacSign)
                            }
                        }
                        .font(Adaptive.size(.footnote, .system(size: 15)))
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .backgroundWithShape(12, .cardBackground, true)

                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("СОВЕТ ДНЯ")
                                .font(Adaptive.size(.callout, .default))
                                .fontWeight(.heavy)

                            if vm.needsAIConsent {
                                AIConsentLock(title: "Разрешите анализ с помощью AI, чтобы получать совет дня",
                                              onAllow: aiConsentButton)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(vm.profileDisplayHandler.dailyTip)
                                    .font(.system(size: Adaptive.size(14, 15))).italic()
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AccentColorOption.color(accentColor))
                        .clipShape(.rect(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("О вас")
                                .font(Adaptive.size(.system(size: 15), .default))
                                .bold()

                            Text(vm.profileDisplayHandler.overview)
                                .font(.system(size: Adaptive.size(14, 15)))
                                .foregroundStyle(.deepGray)

                            VStack {
                                TestResultCellView(test: PersonalityCellTypes.socialFilter,
                                                   description: vm.profileDisplayHandler.socialFilter)

                                Divider()

                                TestResultCellView(test: PersonalityCellTypes.emotionalDepth,
                                                   description: vm.profileDisplayHandler.emotionalDepth)
                            }
                            .testTopicsModifier()
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(12, .cardBackground, true)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ваш психотип")
                                .font(Adaptive.size(.system(size: 15), .default))
                                .bold()

                            VStack(spacing: 15) {
                                EmotionalProfileBar(type: .temperament, value: vm.profileDisplayHandler.temperament)
                                EmotionalProfileBar(type: .thinking, value: vm.profileDisplayHandler.thinking)
                                EmotionalProfileBar(type: .organization, value: vm.profileDisplayHandler.organization)
                                EmotionalProfileBar(type: .relationships, value: vm.profileDisplayHandler.relationships)
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
                            CompleteProfileLock(title: "Пройдите тесты для получения результатов о себе")
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
                     user: .mock) {

        }
    }
}
