//
//  ProfileViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import Combine
import SwiftUI

enum ProfileRoutes: Hashable {
    case completeProfile, settings
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profileRoutes: [ProfileRoutes] = []
    
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    
    @Published private(set) var authState: AuthState
    @Published var showSettings = false
    @Published private(set) var isAuthLoading = false
    @Published var authErrorMessage: String?
    @Published var showAuthError = false

    private let authService: any AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var isProfileCompleted: Bool {
        return false
    }

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
        self.authState = authService.authState

        authService.authStatePublisher
            .sink { [weak self] authState in
                Task { @MainActor in
                    self?.authState = authState
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }

    func signIn(onSuccess: @escaping () -> Void) {
        performAuthAction(onSuccess: onSuccess) { [weak self] in
            guard let self else { return }
            
            try await authService.signIn(email: self.email,
                                         password: self.password)
        }
    }

    func createAccount(onSuccess: @escaping () -> Void) {
        performAuthAction(onSuccess: onSuccess) { [weak self] in
            guard let self else { return }
            
            try await authService.createAccount(name: self.name,
                                                email: self.email,
                                                password: self.password)
        }
    }

    func signOut() {
        authService.signOut()
        authState = authService.authState
    }

    
    private func performAuthAction(onSuccess: @escaping () -> Void,
                                   action: @escaping () async throws -> Void) {
        guard !isAuthLoading else { return }

        Task {
            isAuthLoading = true

            do {
                try await action()
                authState = authService.authState
                clearAuthFields()
                onSuccess()
            } catch {
                authErrorMessage = error.localizedDescription
                showAuthError = true
            }

            isAuthLoading = false
        }
    }

    private func clearAuthFields() {
        name = ""
        email = ""
        password = ""
    }
}
