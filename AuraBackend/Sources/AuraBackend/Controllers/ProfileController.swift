//
//  ProfileController.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct ProfileController: RouteCollection {
    private let horoscopeService = HoroscopeService()

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
            .grouped(UserAuthMiddleware())

        auth.patch("profileInfo", use: updateProfileInfo)
    }

    private func updateProfileInfo(_ req: Request) async throws -> UpdateProfileInfoResponse {
        let user = try req.auth.require(User.self)
        let profileInfo = try req.content.decode(UpdateProfileInfoRequest.self)

        guard let dateOfBirth = UserDateFormatter.birthDate(from: profileInfo.dateOfBirth) else {
            throw Abort(.badRequest, reason: "Укажите корректную дату рождения в формате ДД.ММ.ГГГГ")
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

        user.dateOfBirth = dateOfBirth
        user.birthTime = birthTime
        user.gender = profileInfo.gender
        user.socialType = profileInfo.socialType
        user.conflictStyle = profileInfo.conflictStyle
        user.emotionalCore = profileInfo.emotionalCore
        user.decisionStyle = profileInfo.decisionStyle
        user.coreFocus = profileInfo.coreFocus

        try await user.save(on: req.db)

        let horoscope = try await horoscopeService.makeHoroscope(for: user, req: req, on: req.db)

        return UpdateProfileInfoResponse(user: try user.toDTO(), horoscope: horoscope)
    }

    private func emptyStringToNil(_ string: String?) -> String? {
        guard let string else { return nil }
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedString.isEmpty ? nil : trimmedString
    }
}
