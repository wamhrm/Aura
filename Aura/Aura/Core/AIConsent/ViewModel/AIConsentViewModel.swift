//
//  AIConsentViewModel.swift
//  Aura
//
//  Created by wamhrm on 23.10.2026.
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

    init(authService: any AuthServiceProtocol, promptsAutomatically: Bool = true) {
        self.authService = authService
        wasPromptedAutomatically = !promptsAutomatically

        setupSubscriptions()
    }

    var allowButtonTitle: String {
        isLoading ? "Сохраняем..." : "Разрешить"
    }

    private func setupSubscriptions() {
        authService.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, case .signedIn(let user) = $0 else { return }
                promptIfNeeded(user)
            }
            .store(in: &cancellables)
    }

    private func promptIfNeeded(_ user: UserModel) {
        guard !user.allowsAIAnalysis, !wasPromptedAutomatically else { return }

        wasPromptedAutomatically = true
        showConsent = true
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
                alertMessage = error.userMessage
                showAlert = true
            }

            isLoading = false
        }
    }

    func decline() {
        showConsent = false
    }
}
