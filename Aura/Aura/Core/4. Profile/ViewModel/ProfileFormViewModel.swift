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
    @Published var name: String
    @Published var birthDate: Date
    @Published var knowsBirthTime: Bool
    @Published var birthTime: Date

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol, user: UserModel) {
        self.authService = authService
        profileInfo = user.profileInfo
        name = user.name
        birthDate = user.dateOfBirth.flatMap(BirthDateFormatter.date(from:)) ?? BirthDateFormatter.defaultDate
        knowsBirthTime = user.birthTime != nil
        birthTime = user.birthTime.flatMap(BirthDateFormatter.time(from:)) ?? BirthDateFormatter.defaultTime
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
                profileInfo.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                profileInfo.dateOfBirth = BirthDateFormatter.dateString(from: birthDate)
                profileInfo.birthTime = knowsBirthTime ? BirthDateFormatter.timeString(from: birthTime) : ""
                _ = try await authService.updateProfileInfo(profileInfo)
                onSuccess()
            } catch {
                presentAlert(error.userMessage)
            }

            isLoading = false
        }
    }

    private func validateProfileInfoForms() throws {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= InputLimits.minNameLength else {
            throw ProfileInfoError.invalidName
        }

        guard profileInfo.hasAllAnswers else {
            throw ProfileInfoError.incompleteProfileInfo
        }
    }
}

fileprivate enum ProfileInfoError: LocalizedError {
    case invalidName, incompleteProfileInfo

    var errorDescription: String? {
        switch self {
            case .invalidName: "Имя должно содержать минимум \(InputLimits.minNameLength) символа"
            case .incompleteProfileInfo: "Заполните все обязательные поля профиля"
        }
    }
}
