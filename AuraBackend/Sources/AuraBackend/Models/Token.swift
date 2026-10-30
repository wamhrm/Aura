//
//  Token.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

final class Token: Model, Authenticatable, @unchecked Sendable {
    static let schema = "tokens"
    static let lifetime: TimeInterval = 90 * 24 * 60 * 60
    static let renewalInterval: TimeInterval = 24 * 60 * 60

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    @Field(key: "expires_at")
    var expiresAt: Date

    init() {}

    init(value: String,
         userID: User.IDValue,
         expiresAt: Date) {
        self.value = value
        self.$user.id = userID
        self.expiresAt = expiresAt
    }
}

extension Token {
    static func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).hex
    }
}
