import Fluent
import Vapor

struct ProfileController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
            .grouped(UserAuthMiddleware())
            
        auth.patch("profileInfo", use: updateProfileInfo)
    }

    private func updateProfileInfo(_ req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        let profileInfo = try req.content.decode(UpdateProfileInfoRequest.self)

        guard let dateOfBirth = UserDateFormatter.date(from: profileInfo.dateOfBirth) else {
            throw Abort(.badRequest, reason: "Укажите дату рождения в формате ДД.ММ.ГГГГ")
        }

        user.dateOfBirth = dateOfBirth
        user.birthTime = emptyStringToNil(profileInfo.birthTime)
        user.gender = profileInfo.gender
        user.socialType = profileInfo.socialType
        user.conflictStyle = profileInfo.conflictStyle
        user.emotionalCore = profileInfo.emotionalCore
        user.decisionStyle = profileInfo.decisionStyle
        user.coreFocus = profileInfo.coreFocus

        try await user.save(on: req.db)
        return try user.toDTO()
    }

    private func emptyStringToNil(_ string: String?) -> String? {
        guard let string else { return nil }
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedString.isEmpty ? nil : trimmedString
    }
}
