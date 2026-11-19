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
            switch authService.restorationState {
                case .loading:
                    LoadingView(title: "Входим...")
                case .failed(let message):
                    LoadFailedView(message: message, isFullScreen: true) {
                        authService.retryRestoreSession()
                    }
                case .loaded where authService.showsMainScreen:
                    MainTabView(authService: authService, contentService: contentService)
                        .transition(.opacity)
                case .loaded:
                    OnboardingView(authService: authService)
                        .transition(.opacity)
            }
        }
        .task { await authService.restoreSession() }
        .animation(.easeInOut(duration: 0.3), value: authService.restorationState)
        .animation(.easeInOut(duration: 0.3), value: authService.showsMainScreen)
    }
}

#Preview {
    let services = PreviewServices(signedIn: false)
    RootView(authService: services.authService,
             contentService: services.contentService)
}
