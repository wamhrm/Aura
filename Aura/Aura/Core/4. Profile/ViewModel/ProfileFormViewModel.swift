//
//  ProfileFormViewModel.swift
//  Aura
//
//  Created by wamhrm on 03.11.2026.
//

import Combine
import Foundation

@MainActor
final class ProfileFormViewModel: ObservableObject, AlertPresentable {
    @Published var profileInfo: ProfileInfoModel

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol, user: UserModel) {
        self.authService = authService
        profileInfo = user.profileInfo
    }

    var saveButtonTitle: String {
        isLoading ? "Сохраняем..." : "Готово"
    }

    func saveProfileInfo(onSuccess: @escaping () -> Void) {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                try validateProfileInfoForms()
                _ = try await authService.updateProfileInfo(profileInfo)
                onSuccess()
            } catch {
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }

    private func validateProfileInfoForms() throws {
        guard profileInfo.dateOfBirth.count == 10 else {
            throw ProfileInfoError.invalidDateOfBirth
        }

        guard profileInfo.hasAllAnswers else {
            throw ProfileInfoError.incompleteProfileInfo
        }
    }
}

fileprivate enum ProfileInfoError: LocalizedError {
    case invalidDateOfBirth, incompleteProfileInfo

    var errorDescription: String? {
        switch self {
            case .invalidDateOfBirth: "Укажите дату рождения в формате ДД.ММ.ГГГГ"
            case .incompleteProfileInfo: "Заполните все обязательные поля профиля"
        }
    }
}
