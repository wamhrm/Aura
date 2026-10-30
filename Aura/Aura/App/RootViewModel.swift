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

    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol) {
        if case .signedIn(let user) = authService.authState.value, user.hasCompletedProfileInfo {
            screen = .main
        } else {
            screen = .onboarding
        }

        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self, case .signedOut = state, screen == .main else { return }
                hasFinishedOnboarding = false
                withAnimation(.easeInOut(duration: 0.3)) { screen = .onboarding }
            }
            .store(in: &cancellables)
    }
    
    func finishOnboarding() {
        hasFinishedOnboarding = true
        withAnimation(.easeInOut(duration: 0.3)) { screen = .main }
    }
}
