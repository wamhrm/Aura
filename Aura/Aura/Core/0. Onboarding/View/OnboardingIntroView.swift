//
//  OnboardingIntroView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct OnboardingIntroView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var page = 0
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $page) {
                ForEach(IntroPages.allCases, id: \.self) { item in
                    pageView(item)
                        .tag(item.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(IntroPages.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item.rawValue == page ? AccentColorOption.color(accentColor) : Color.fieldBorder)
                        .frame(width: item.rawValue == page ? 22 : 8, height: 8)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: page)

            VStack(spacing: 15) {
                ClassicButton(title: isLastPage ? "Начать" : "Далее") {
                    if isLastPage {
                        vm.start()
                    } else {
                        withAnimation { page += 1 }
                    }
                }

                OnboardingTextButton(title: "У меня уже есть аккаунт") {
                    vm.showSignIn()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }
}

extension OnboardingIntroView {
    private var isLastPage: Bool {
        page == IntroPages.allCases.count - 1
    }

    private func pageView(_ item: IntroPages) -> some View {
        VStack(spacing: 25) {
            Spacer()

            if let icon = item.icon {
                OnboardingIcon(icon: icon, size: Adaptive.size(130, 150))
            } else {
                LogoImage(size: Adaptive.size(130, 150))
            }

            VStack(spacing: 10) {
                Text(item.title)
                    .font(Adaptive.size(.title2, .title))
                    .bold()

                Text(item.subtitle)
                    .font(Adaptive.size(.callout, .body))
                    .foregroundStyle(.deepGray)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 25)

            Spacer()
        }
    }
}

fileprivate enum IntroPages: Int, CaseIterable {
    case welcome
    case horoscope
    case daily
    case tests

    var icon: String? {
        switch self {
            case .welcome: nil
            case .horoscope: "moon.stars"
            case .daily: "sun.max"
            case .tests: "heart.text.square"
        }
    }

    var title: String {
        switch self {
            case .welcome: "Добро пожаловать"
            case .horoscope: "Гороскоп на неделю"
            case .daily: "Инсайт и совет дня"
            case .tests: "Тесты о вас и совместимость"
        }
    }

    var subtitle: String {
        switch self {
            case .welcome: "Гороскоп, инсайты и психологические тесты, которые помогают лучше понять себя и других"
            case .horoscope: "Прогноз о любви, здоровье и работе для вашего знака зодиака"
            case .daily: "Каждый день — короткая персональная подсказка о вашем состоянии и том, на что обратить внимание"
            case .tests: "Узнайте свой психотип и проверьте совместимость с партнёром"
        }
    }
}

#Preview {
    OnboardingIntroView(vm: OnboardingViewModel(authService: AuthService(),
                                                contentService: ContentService()) {})
}
