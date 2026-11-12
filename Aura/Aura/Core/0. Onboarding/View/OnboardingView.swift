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
            NavigationStack(path: $vm.onboardingRoutes) {
                ZStack {
                    BackgroundView()

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
                }
                .navigationDestination(for: OnboardingRoutes.self) { destination in
                    destinationView(destination)
                        .navigationBarBackButtonHidden(vm.isOnlyStepOfSignedInUser)
                        .toolbar {
                            if vm.isOnlyStepOfSignedInUser {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button {
                                        vm.goBack()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                    }
                                }
                            }
                        }
                }
            }
            .opacity(vm.isLoading ? 0 : 1)

            ZStack {
                BackgroundView()
                LoadingView(title: vm.loadingTitle, isPresented: vm.isLoading)
            }
            .opacity(vm.isLoading ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.35), value: vm.isLoading)
        .alert(vm.alertMessage, isPresented: vm.alertBinding) {
            Button("ОК", role: .cancel) { }
        }
        .alert("Выйти из аккаунта?", isPresented: Binding {
            vm.showSignOutAlert
        } set: { newValue in
            if vm.showSignOutAlert != newValue { vm.showSignOutAlert = newValue }
        }) {
            Button("Отмена", role: .cancel) {}
            Button("Выйти", role: .destructive) {
                vm.signOut()
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
                AIConsentView(allow: { vm.chooseAIConsent(true) },
                              decline: { vm.chooseAIConsent(false) })
        }
    }
}

#Preview {
    OnboardingView(authService: AuthService.preview)
}
