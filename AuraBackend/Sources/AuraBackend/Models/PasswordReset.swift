//
//  PasswordReset.swift
//  AuraBackend
//
//  Created by wamhrm on 27.10.2026.
//

import Fluent
import Foundation

final class PasswordReset: Model, @unchecked Sendable {
    static let schema = "password_resets"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "code_hash")
    var codeHash: String

    @Field(key: "expires_at")
    var expiresAt: Date

    @Field(key: "attempts")
    var attempts: Int

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(userID: User.IDValue, codeHash: String, expiresAt: Date) {
        self.$user.id = userID
        self.codeHash = codeHash
        self.expiresAt = expiresAt
        self.attempts = 0
    }
}
