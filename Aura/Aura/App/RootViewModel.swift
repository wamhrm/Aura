//
//  RootViewModel.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import Combine
import SwiftUI

enum RootScreen {
    case onboarding, main
}

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var screen: RootScreen
    @Published private(set) var hasFinishedOnboarding = false

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    private let refreshInterval: TimeInterval

    private var lastRefreshDate = Date()
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol,
         refreshInterval: TimeInterval = 5 * 60) {
        self.authService = authService
        self.contentService = contentService
        self.refreshInterval = refreshInterval

        if case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            screen = .main
        } else {
            screen = .onboarding
        }

        authService.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, case .signedOut = state, screen == .main else { return }
                hasFinishedOnboarding = false
                withAnimation(.easeInOut(duration: 0.3)) { screen = .onboarding }
            }
            .store(in: &cancellables)
    }
    
    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }

        restoreSession()

        guard Date().timeIntervalSince(lastRefreshDate) >= refreshInterval else { return }

        lastRefreshDate = Date()
        authService.refreshUser()
        contentService.refreshRequested.send()
    }

    private func restoreSession() {
        guard case .signedOut = authService.authState.value else { return }

        authService.restoreSessionIfNeeded()

        if screen == .onboarding, case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            screen = .main
        }
    }

    func finishOnboarding() {
        hasFinishedOnboarding = true
        withAnimation(.easeInOut(duration: 0.3)) { screen = .main }
    }
}
