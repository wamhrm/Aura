//
//  User.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

final class User: Model, Authenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @OptionalField(key: "email")
    var email: String?

    @OptionalField(key: "date_of_birth")
    var dateOfBirth: Date?

    @OptionalField(key: "birth_time")
    var birthTime: String?

    @OptionalField(key: "gender")
    var gender: String?

    @OptionalField(key: "social_type")
    var socialType: String?

    @OptionalField(key: "conflict_style")
    var conflictStyle: String?

    @OptionalField(key: "emotional_core")
    var emotionalCore: String?

    @OptionalField(key: "decision_style")
    var decisionStyle: String?

    @OptionalField(key: "core_focus")
    var coreFocus: String?

    @OptionalField(key: "ai_consent_at")
    var aiConsentAt: Date?

    @OptionalField(key: "password_hash")
    var passwordHash: String?

    @OptionalField(key: "apple_user_id")
    var appleUserID: String?

    @OptionalField(key: "apple_refresh_token")
    var appleRefreshToken: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(name: String,
         email: String,
         passwordHash: String) {
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }

    init(name: String, appleUserID: String) {
        self.name = name
        self.appleUserID = appleUserID
    }
}

extension User {
    var hasCompletedProfileInfo: Bool {
        dateOfBirth != nil &&
        gender != nil &&
        socialType != nil &&
        conflictStyle != nil &&
        emotionalCore != nil &&
        decisionStyle != nil &&
        coreFocus != nil
    }

    func toDTO() throws -> UserDTO {
        UserDTO(id: try requireID(),
                name: name,
                email: email,
                dateOfBirth: dateOfBirth.map(UserDateFormatter.string(from:)),
                birthTime: birthTime,
                gender: gender,
                socialType: socialType,
                conflictStyle: conflictStyle,
                emotionalCore: emotionalCore,
                decisionStyle: decisionStyle,
                coreFocus: coreFocus,
                hasAIConsent: aiConsentAt != nil)
    }
}
