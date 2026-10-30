//
//  OnboardingIntroView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct OnboardingIntroView: View {
    @ObservedObject var vm: OnboardingViewModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $vm.introPage) {
                ForEach(IntroPages.allCases, id: \.self) { item in
                    pageView(item)
                        .tag(item.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(IntroPages.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item.rawValue == vm.introPage ? AccentColorOption.color(accentColor) : Color.fieldBorder)
                        .frame(width: item.rawValue == vm.introPage ? 22 : 8, height: 8)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.introPage)

            VStack(spacing: 15) {
                ClassicButton(title: vm.introButtonTitle) {
                    vm.showNextIntroPage()
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

#Preview {
    OnboardingIntroView(vm: OnboardingViewModel(authService: AuthService(),
                                                contentService: ContentService()) {})
}
