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

    @Published private var alertPresented = false
    @Published var alertMessage = ""

    var showAlert: Bool {
        get { alertPresented }
        set {
            guard alertPresented != newValue else { return }
            alertPresented = newValue
        }
    }

    init(user: UserModel) {
        profileInfo = user.profileInfo
        name = user.name.capitalized
        birthDate = user.dateOfBirth.flatMap(BirthDateFormatter.date(string:)) ?? BirthDateFormatter.defaultDate
        knowsBirthTime = user.birthTime != nil
        birthTime = user.birthTime.flatMap(BirthDateFormatter.time(string:)) ?? BirthDateFormatter.defaultTime
    }

    func profileInfoRequest() throws -> ProfileInfoModel {
        try validateProfileInfoForms()

        var request = profileInfo
        request.name = name.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
        request.dateOfBirth = BirthDateFormatter.dateString(date: birthDate)
        request.birthTime = knowsBirthTime ? BirthDateFormatter.timeString(date: birthTime) : ""
        return request
    }

    private func validateProfileInfoForms() throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= InputLimits.minNameLength else {
            throw ProfileInfoError.invalidName
        }

        guard name.count <= InputLimits.maxNameLength else {
            throw ProfileInfoError.nameTooLong
        }

        guard profileInfo.hasAllAnswers else {
            throw ProfileInfoError.incompleteProfileInfo
        }
    }
}

fileprivate enum ProfileInfoError: LocalizedError {
    case invalidName, nameTooLong, incompleteProfileInfo

    var errorDescription: String? {
        switch self {
            case .invalidName: AppLanguage.text("Имя должно содержать минимум \(InputLimits.minNameLength) символа")
            case .nameTooLong: AppLanguage.text("Имя должно быть не длиннее \(InputLimits.maxNameLength) символов")
            case .incompleteProfileInfo: AppLanguage.text("Заполните все обязательные поля профиля")
        }
    }
}
