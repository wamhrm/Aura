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
    private let storage: any LocalStorageProtocol

    init(authService: AuthService,
         contentService: ContentService,
         storage: any LocalStorageProtocol) {
        self.authService = authService
        self.contentService = contentService
        self.storage = storage
        _vm = StateObject(wrappedValue: RootViewModel(authService: authService))
    }

    var body: some View {
        Group {
            switch vm.screen {
                case .onboarding:
                    OnboardingView(authService: authService,
                                   contentService: contentService,
                                   storage: storage) {
                        vm.finishOnboarding()
                    }
                    .transition(.opacity)
                case .main:
                    MainTabView(authService: authService,
                                contentService: contentService,
                                storage: storage,
                                promptsAIConsentAutomatically: !vm.hasFinishedOnboarding)
                        .transition(.opacity)
            }
        }
    }
}

#Preview {
    RootView(authService: AuthService(),
             contentService: ContentService(),
             storage: LocalStorage())
}
