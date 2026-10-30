//
//  OnboardingView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         onFinish: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(authService: authService,
                                                            contentService: contentService,
                                                            onFinish: onFinish))
    }

    var body: some View {
        NavigationStack(path: $vm.onboardingRoutes) {
            ZStack {
                BackgroundView()

                OnboardingIntroView(vm: vm)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: OnboardingRoutes.self) { destination in
                destinationView(destination)
            }
        }
        .disabled(vm.isLoading)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) { }
        }
    }
}

extension OnboardingView {
    private func destinationView(_ route: OnboardingRoutes) -> some View {
        ZStack {
            BackgroundView()
                .dismissKeyboardOnTap()

            VStack(spacing: 0) {
                if route != .loading {
                    OnboardingTopBar(progress: route.progress)
                }

                stepView(route)
                    .frame(maxHeight: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(route == .loading)
    }

    @ViewBuilder
    private func stepView(_ route: OnboardingRoutes) -> some View {
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
                AIConsentStepView(vm: vm)
            case .notifications:
                NotificationsStepView(vm: vm)
            case .loading:
                LoadingStepView(vm: vm)
        }
    }
}

#Preview {
    OnboardingView(authService: AuthService(),
                   contentService: ContentService()) {}
}
