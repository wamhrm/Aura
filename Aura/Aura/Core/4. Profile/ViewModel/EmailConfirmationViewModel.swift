//
//  EmailConfirmationViewModel.swift
//  Aura
//
//  Created by wamhrm on 03.11.2026.
//

import Combine
import Foundation

@MainActor
final class EmailConfirmationViewModel: ObservableObject, AlertPresentable, Identifiable {
    @Published var code = ""

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isCodeSent = false
    @Published private(set) var isLoading = false

    private let authService: any AuthServiceProtocol
    private let email: String

    init(authService: any AuthServiceProtocol, email: String) {
        self.authService = authService
        self.email = email
    }

    var subtitle: String {
        isCodeSent
            ? "Мы отправили код на \(email). Введите его, чтобы проходить тесты"
            : "Чтобы проходить тесты, подтвердите почту \(email). Мы отправим на неё код"
    }

    var sendCodeButtonTitle: String {
        isLoading ? "Отправляем..." : "Подтвердить"
    }

    var confirmButtonTitle: String {
        isLoading ? "Проверяем..." : "Проверить код"
    }

    func sendCode() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try await authService.sendEmailConfirmationCode()
                isCodeSent = true
            } catch {
                // The sheet was reopened and the code sent a moment ago still works, so its field must be reachable
                if case NetworkError.limited = error { isCodeSent = true }
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }

    // After success the screen below sees the confirmed user and closes this sheet
    func confirm() {
        guard !isLoading else { return }

        let code = code.trimmingCharacters(in: .whitespacesAndNewlines)

        guard code.count == InputLimits.resetCodeLength else {
            presentAlert("Код состоит из \(InputLimits.resetCodeLength) цифр")
            return
        }

        isLoading = true

        Task {
            do {
                try await authService.confirmEmail(code: code)
            } catch {
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }
}
