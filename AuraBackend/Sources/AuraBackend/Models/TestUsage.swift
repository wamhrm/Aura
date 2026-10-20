//
//  TestUsage.swift
//  AuraBackend
//
//  Created by ddorsat on 21.10.2026.
//

import Fluent
import Foundation

final class TestUsage: Model, @unchecked Sendable {
    static let schema = "test_usages"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(userID: User.IDValue) {
        self.$user.id = userID
    }
}
