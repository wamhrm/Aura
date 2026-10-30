//
//  RootView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct RootView: View {
    @StateObject private var vm: RootViewModel

    private let authService: AuthService
    private let contentService: ContentService

    init(authService: AuthService,
         contentService: ContentService) {
        self.authService = authService
        self.contentService = contentService
        _vm = StateObject(wrappedValue: RootViewModel(authService: authService))
    }

    var body: some View {
        Group {
            switch vm.screen {
                case .onboarding:
                    OnboardingView(authService: authService,
                                   contentService: contentService) {
                        vm.finishOnboarding()
                    }
                    .transition(.opacity)
                case .main:
                    MainTabView(authService: authService,
                                contentService: contentService,
                                promptsAIConsentAutomatically: !vm.hasFinishedOnboarding)
                        .transition(.opacity)
            }
        }
    }
}

#Preview {
    RootView(authService: AuthService(),
             contentService: ContentService())
}
