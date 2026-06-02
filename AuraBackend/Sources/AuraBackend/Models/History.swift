//
//  History.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Foundation

final class History: Model, @unchecked Sendable {
    static let schema = "history"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "kind")
    var kind: TestKind

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "selected_tests")
    var selectedTests: [String]

    @Field(key: "result")
    var result: String

    init() {}

    init(userID: User.IDValue,
         kind: TestKind,
         selectedTests: [String],
         result: String) {
        self.$user.id = userID
        self.kind = kind
        self.selectedTests = selectedTests
        self.result = result
    }
}

enum TestKind: String, Codable, Sendable {
    case personality
    case compatibility
}
