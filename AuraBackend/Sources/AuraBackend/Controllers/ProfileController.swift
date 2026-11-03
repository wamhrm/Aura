//
//  ProfileController.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct ProfileController: RouteCollection {
    private let horoscopeService = HoroscopeService()

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
            .grouped(UserAuthMiddleware())

        auth.get("me", use: fetchCurrentUser)
        auth.patch("profileInfo", use: updateProfileInfo)
        auth.post("aiConsent", use: giveAIConsent)
    }

    private func fetchCurrentUser(_ req: Request) async throws -> UserDTO {
        try req.auth.require(User.self).toDTO()
    }

    private func giveAIConsent(_ req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)

        if user.aiConsentAt == nil {
            user.aiConsentAt = Date()
            try await user.save(on: req.db)
        }

        return try user.toDTO()
    }

    private func updateProfileInfo(_ req: Request) async throws -> UpdateProfileInfoResponse {
        let user = try req.auth.require(User.self)
        let profileInfo = try req.content.decode(UpdateProfileInfoRequest.self)

        guard let dateOfBirth = UserDateFormatter.birthDate(from: profileInfo.dateOfBirth) else {
            throw Abort(.badRequest, reason: "Укажите корректную дату рождения в формате ДД.ММ.ГГГГ")
        }

        guard UserDateFormatter.isOldEnough(dateOfBirth) else {
            throw Abort(.badRequest, reason: "Aura доступна с 16 лет")
        }

        let birthTime = emptyStringToNil(profileInfo.birthTime)

        if let birthTime, !UserDateFormatter.isValidTime(birthTime) {
            throw Abort(.badRequest, reason: "Укажите время рождения в формате ЧЧ:ММ")
        }

        guard ProfileInfoOptions.genders.contains(profileInfo.gender),
              ProfileInfoOptions.socialTypes.contains(profileInfo.socialType),
              ProfileInfoOptions.conflictStyles.contains(profileInfo.conflictStyle),
              ProfileInfoOptions.emotionalCores.contains(profileInfo.emotionalCore),
              ProfileInfoOptions.decisionStyles.contains(profileInfo.decisionStyle),
              ProfileInfoOptions.coreFocuses.contains(profileInfo.coreFocus) else {
            throw Abort(.badRequest, reason: "Некорректные данные профиля")
        }

        if let name = profileInfo.name?.trimmingCharacters(in: .whitespacesAndNewlines) {
            guard name.count >= InputLimits.minNameLength else {
                throw Abort(.badRequest, reason: "Имя должно содержать минимум 2 символа")
            }
            guard name.count <= InputLimits.maxNameLength else {
                throw Abort(.badRequest, reason: "Имя должно быть не длиннее 50 символов")
            }

            user.name = name
        }

        user.dateOfBirth = dateOfBirth
        user.birthTime = birthTime
        user.gender = profileInfo.gender
        user.socialType = profileInfo.socialType
        user.conflictStyle = profileInfo.conflictStyle
        user.emotionalCore = profileInfo.emotionalCore
        user.decisionStyle = profileInfo.decisionStyle
        user.coreFocus = profileInfo.coreFocus

        try await user.save(on: req.db)

        // Never waits for OpenAI: the app requests a missing horoscope on its own
        let horoscope = try? await horoscopeService.findCurrentHoroscope(for: user, in: req.userTimeZone, on: req.db)

        return UpdateProfileInfoResponse(user: try user.toDTO(), horoscope: horoscope)
    }

    private func emptyStringToNil(_ string: String?) -> String? {
        guard let string else { return nil }
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedString.isEmpty ? nil : trimmedString
    }
}
