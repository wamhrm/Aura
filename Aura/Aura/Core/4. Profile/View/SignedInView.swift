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
                            } else if let dailyTip = vm.profileDisplayHandler.dailyTip {
                                Text(dailyTip)
                                    .font(.system(size: Adaptive.size(14, 15))).italic()
                                    .fontWeight(.medium)
                            } else if case .failed(let message) = vm.tipState {
                                LoadFailedView(message: message) {
                                    vm.retryDailyTip()
                                }
                                .tint(.white)
                            } else {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.tint)
                        .clipShape(.rect(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("О вас")
                                .font(Adaptive.size(.system(size: 15), .default))
                                .bold()

                            if let overview = vm.profileDisplayHandler.overview {
                                Text(overview)
                                    .font(.system(size: Adaptive.size(14, 15)))
                                    .foregroundStyle(.deepGray)
                            }

                            if vm.profileDisplayHandler.hasTopics {
                                VStack {
                                    if let socialFilter = vm.profileDisplayHandler.socialFilter {
                                        TestResultCellView(test: PersonalityCellTypes.socialFilter,
                                                           description: socialFilter)
                                    }

                                    if vm.profileDisplayHandler.hasBothTopics {
                                        Divider()
                                    }

                                    if let emotionalDepth = vm.profileDisplayHandler.emotionalDepth {
                                        TestResultCellView(test: PersonalityCellTypes.emotionalDepth,
                                                           description: emotionalDepth)
                                    }
                                }
                                .testTopicsModifier()
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .backgroundWithShape(12, .cardBackground, true)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ваш психотип")
                                .font(Adaptive.size(.system(size: 15), .default))
                                .bold()

                            VStack(spacing: 15) {
                                if let temperament = vm.profileDisplayHandler.temperament {
                                    EmotionalProfileBar(type: .temperament, value: temperament)
                                }

                                if let thinking = vm.profileDisplayHandler.thinking {
                                    EmotionalProfileBar(type: .thinking, value: thinking)
                                }

                                if let organization = vm.profileDisplayHandler.organization {
                                    EmotionalProfileBar(type: .organization, value: organization)
                                }

                                if let relationships = vm.profileDisplayHandler.relationships {
                                    EmotionalProfileBar(type: .relationships, value: relationships)
                                }
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
                            lockedContentView()
                                .padding(.bottom, 500)
                        }
                    }
                }
                .padding(.horizontal)
                .bottomAreaPadding(15)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await vm.refresh()
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension SignedInView {
    @ViewBuilder
    private func lockedContentView() -> some View {
        switch vm.personalityState {
            case .loading:
                ProgressView()
            case .loaded:
                CompleteProfileLock(title: "Пройдите тесты для получения результатов о себе")
            case .failed(let message):
                LoadFailedView(message: message) {
                    vm.retryPersonality()
                }
                .padding(20)
                .backgroundWithShape(12, .cardBackground, true)
                .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        SignedInView(vm: ProfileViewModel(authService: AuthService.preview,
                                          contentService: ContentService.preview),
                     user: .mock) {

        }
    }
}
