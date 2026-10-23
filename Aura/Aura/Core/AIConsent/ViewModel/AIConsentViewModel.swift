//
//  AIConsentViewModel.swift
//  Aura
//
//  Created by ddorsat on 23.10.2026.
//

import Combine
import Foundation

@MainActor
final class AIConsentViewModel: ObservableObject {
    @Published var showConsent = false
    @Published var showAlert = false
    @Published private(set) var alertMessage = ""
    @Published private(set) var isLoading = false

    private let authService: any AuthServiceProtocol

    private var wasPromptedAutomatically = false
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol) {
        self.authService = authService

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.handleAuthState($0)
            }
            .store(in: &cancellables)
    }

    private func handleAuthState(_ state: AuthState) {
        switch state {
            case .signedIn(let user):
                guard user.hasCompletedProfileInfo,
                      !user.allowsAIAnalysis,
                      !wasPromptedAutomatically else { return }

                wasPromptedAutomatically = true
                showConsent = true
            case .signedOut:
                wasPromptedAutomatically = false
                showConsent = false
        }
    }

    func request() {
        showConsent = true
    }

    func accept() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.giveAIConsent()
                showConsent = false
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }

            isLoading = false
        }
    }

    func decline() {
        showConsent = false
    }
}
