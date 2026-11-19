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
    @Published private(set) var showsCodeEntry = false
    @Published private(set) var isLoading = false
    @Published private(set) var loadingTitle: LocalizedStringResource = "Отправляем..."

    private let authService: any AuthServiceProtocol
    private let email: String

    init(authService: any AuthServiceProtocol, email: String) {
        self.authService = authService
        self.email = email
    }

    var subtitle: LocalizedStringResource {
        showsCodeEntry ? "Введите код из письма на \(email), чтобы подтвердить почту."
                       : "Чтобы проходить тесты, подтвердите почту \(email). Мы отправим на неё код."
    }

    var sendCodeButtonTitle: LocalizedStringResource {
        isLoading ? "Отправляем..." : "Подтвердить"
    }

    var confirmButtonTitle: LocalizedStringResource {
        isLoading ? "Проверяем..." : "Проверить код"
    }
    
    var sheetHeight: CGFloat {
        showsCodeEntry ? Adaptive.size(340, 352, 360) : Adaptive.size(200, 212, 220)
    }
    
    func sendCode() {
        guard !isLoading else { return }

        isLoading = true
        loadingTitle = "Отправляем..."

        Task {
            do {
                try await authService.sendEmailConfirmationCode()
                showsCodeEntry = true
            } catch {
                switch error as? NetworkError {
                    case .emailCodeRecentlyRequested, .emailCodeDailyLimit:
                        showsCodeEntry = true
                    default:
                        break
                }
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }

    func confirm() {
        guard !isLoading else { return }

        let code = code.trimmingCharacters(in: .whitespacesAndNewlines)

        guard code.count == InputLimits.resetCodeLength, code.allSatisfy(\.isNumber) else {
            presentAlert(AppLanguage.text("Код состоит из \(InputLimits.resetCodeLength) цифр"))
            return
        }

        isLoading = true
        loadingTitle = "Проверяем..."

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
