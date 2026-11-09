//
//  RootView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct RootView: View {
    @ObservedObject private var authService: AuthService
    private let contentService: ContentService

    init(authService: AuthService,
         contentService: ContentService) {
        self.authService = authService
        self.contentService = contentService
    }

    var body: some View {
        Group {
            if authService.showsMainScreen {
                MainTabView(authService: authService,
                            contentService: contentService,
                            promptsAIConsentAutomatically: !authService.didAskAIConsent)
                    .transition(.opacity)
            } else {
                OnboardingView(authService: authService)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.showsMainScreen)
    }
}

#Preview {
    RootView(authService: AuthService.preview,
             contentService: ContentService.preview)
}
