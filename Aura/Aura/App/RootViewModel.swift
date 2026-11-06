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
    
    func handleScenePhase(_ phase: ScenePhase, now: Date = Date()) {
        guard phase == .active else { return }

        Task {
            await restoreSession()

            let dayChanged = !Calendar.current.isDate(now, inSameDayAs: lastRefreshDate)
            guard case .signedIn = authService.authState.value,
                  dayChanged || now.timeIntervalSince(lastRefreshDate) >= refreshInterval else { return }
            lastRefreshDate = now
            authService.refreshUser()
            contentService.refreshRequested.send()
        }
    }

    private func restoreSession() async {
        guard case .signedOut = authService.authState.value else { return }
        await authService.restoreSessionIfNeeded()

        if screen == .onboarding, case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            screen = .main
        }
    }

    func finishOnboarding() {
        hasFinishedOnboarding = true
        withAnimation(.easeInOut(duration: 0.3)) { screen = .main }
    }
}
