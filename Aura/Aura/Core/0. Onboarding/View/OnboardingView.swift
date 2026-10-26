//
//  OnboardingView.swift
//  Aura
//
//  Created by ddorsat on 27.10.2026.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         storage: any LocalStorageProtocol,
         onFinish: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(authService: authService,
                                                            contentService: contentService,
                                                            storage: storage,
                                                            onFinish: onFinish))
    }

    var body: some View {
        ZStack {
            BackgroundView()
                .dismissKeyboardOnTap()

            VStack(spacing: 0) {
                if showsTopBar {
                    OnboardingTopBar(canGoBack: vm.canGoBack, progress: vm.progress) {
                        vm.back()
                    }
                }

                stepView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(vm.step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
            }
        }
        .disabled(vm.isLoading)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) { }
        }
    }
}

extension OnboardingView {
    private var showsTopBar: Bool {
        vm.step != .intro && vm.step != .loading
    }

    @ViewBuilder
    private var stepView: some View {
        switch vm.step {
            case .intro:
                OnboardingIntroView(vm: vm)
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
                   contentService: ContentService(),
                   storage: LocalStorage()) {}
}
