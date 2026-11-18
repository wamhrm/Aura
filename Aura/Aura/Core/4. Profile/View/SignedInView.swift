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
        let display = vm.profileDisplay

        ZStack {
            BackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: Adaptive.size(12, 12, 14)) {
                    VStack(alignment: .center, spacing: 10) {
                        Text(user.nameInitials)
                            .font(Adaptive.size(.title3, .system(size: 21), .title2))
                            .foregroundStyle(.white)
                            .fontWeight(.heavy)
                            .padding(22)
                            .background(LinearGradient(colors: [.purple,
                                                                .pink.opacity(0.7)],
                                                       startPoint: .top,
                                                       endPoint: .bottom))
                            .clipShape(.circle)

                        Text(user.nameCapitalized)
                            .font(Adaptive.size(.title3, .system(size: 21), .title2))
                            .fontWeight(.bold)

                        HStack(alignment: .center, spacing: 5) {
                            Text(user.dateOfBirthHandler)

                            if let zodiacSign = user.zodiacSign {
                                Text("·")
                                    .font(Adaptive.size(.title3, .system(size: 21), .title2))
                                    .bold()

                                Text(zodiacSign.title)
                            }
                        }
                        .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .backgroundWithShape(12, .cardBackground, true)

                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(AppLanguage.text("СОВЕТ ДНЯ"))
                                .font(Adaptive.size(.callout, .default, .default))
                                .fontWeight(.heavy)

                            if vm.needsAIConsent {
                                AIConsentLock(title: AppLanguage.text("Разрешите анализ с помощью AI, чтобы получать совет дня"),
                                              onAllow: aiConsentButton)
                                    .frame(maxWidth: .infinity)
                            } else if let dailyTip = display.dailyTip {
                                Text(dailyTip)
                                    .font(.system(size: Adaptive.size(14, 15, 15))).italic()
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
                            Text(AppLanguage.text("О вас"))
                                .font(Adaptive.size(.system(size: 15), .callout, .default))
                                .bold()

                            if let overview = display.overview {
                                Text(overview)
                                    .font(.system(size: Adaptive.size(14, 15, 15)))
                                    .foregroundStyle(.deepGray)
                            }

                            if display.hasTopics {
                                VStack {
                                    if let socialFilter = display.socialFilter {
                                        TestResultCellView(test: PersonalityCellTypes.socialFilter,
                                                           description: socialFilter)
                                    }

                                    if display.hasBothTopics {
                                        Divider()
                                    }

                                    if let emotionalDepth = display.emotionalDepth {
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
                            Text(AppLanguage.text("Ваш психотип"))
                                .font(Adaptive.size(.system(size: 15), .callout, .default))
                                .bold()

                            VStack(spacing: 15) {
                                if let temperament = display.temperament {
                                    EmotionalProfileBar(type: .temperament, value: temperament)
                                }

                                if let thinking = display.thinking {
                                    EmotionalProfileBar(type: .thinking, value: thinking)
                                }

                                if let organization = display.organization {
                                    EmotionalProfileBar(type: .organization, value: organization)
                                }

                                if let relationships = display.relationships {
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
        .navigationTitle(AppLanguage.text("Профиль"))
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
                CompleteProfileLock(title: AppLanguage.text("Пройдите тесты для получения результатов о себе"))
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
    let services = PreviewServices()
    NavigationStack {
        SignedInView(vm: ProfileViewModel(authService: services.authService,
                                          contentService: services.contentService),
                     user: .mock) {

        }
    }
}
