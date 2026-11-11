//
//  OnboardingView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel

    init(authService: any AuthServiceProtocol) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(authService: authService))
    }

    var body: some View {
        ZStack {
            onboardingStack()

            if vm.isLoading {
                ZStack {
                    BackgroundView()
                    
                    LoadingView(title: vm.activityTitle)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: vm.isLoading)
        .disabled(vm.isLoading)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) { }
        }
        .alert("Выйти из аккаунта?", isPresented: $vm.showSignOutAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Выйти", role: .destructive) {
                vm.signOut()
            }
        }
    }

    private func onboardingStack() -> some View {
        NavigationStack(path: $vm.onboardingRoutes) {
            ZStack {
                BackgroundView()

                if !vm.isPreparingProfile && !vm.hasLoadingFailed {
                    VStack(spacing: 20) {
                        TabView(selection: $vm.introPage) {
                            ForEach(IntroPages.allCases, id: \.self) { item in
                                VStack(spacing: 20) {
                                    Spacer()

                                    if let icon = item.icon {
                                        OnboardingIcon(icon: icon, size: Adaptive.size(80, 100))
                                    } else {
                                        LogoImage(size: Adaptive.size(80, 100))
                                    }

                                    VStack(spacing: 15) {
                                        Text(item.title)
                                            .font(Adaptive.size(.title3, .title2))
                                            .bold()

                                        Text(item.subtitle)
                                            .font(Adaptive.size(.caption2, .callout))
                                            .foregroundStyle(.deepGray)
                                    }
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 25)

                                    Spacer()
                                }
                                .tag(item.rawValue)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))

                        HStack(spacing: 8) {
                            ForEach(IntroPages.allCases, id: \.self) { item in
                                Capsule()
                                    .fill(item.rawValue == vm.introPage ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.fieldBorder))
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
                    .transition(.opacity)
                } else {
                    LoadingView(title: vm.loadingTitle)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: vm.isPreparingProfile)
            .animation(.easeInOut(duration: 0.35), value: vm.hasLoadingFailed)
            .navigationDestination(for: OnboardingRoutes.self) { destination in
                destinationView(destination)
            }
        }
    }
}

extension OnboardingView {
    @ViewBuilder
    private func destinationView(_ route: OnboardingRoutes) -> some View {
        switch route {
            case .nameAndBirth:
                NameAndBirthStepView(vm: vm)
            case .email:
                EmailStepView(vm: vm)
            case .password:
                PasswordStepView(vm: vm)
            case .signIn:
                SignInStepView(vm: vm)
            case .resetPassword:
                ResetPasswordStepView(vm: vm)
            case .psychotype:
                PsychotypeStepView(vm: vm)
            case .aiConsent:
                AIConsentView(title: vm.aiConsentButtonTitle,
                              isDisabled: vm.isLoading,
                              allow: { vm.chooseAIConsent(true) },
                              decline: { vm.chooseAIConsent(false) },
                              back: vm.goBack)
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    OnboardingView(authService: AuthService.preview)
}
