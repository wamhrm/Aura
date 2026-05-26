//
//  DailyContent.swift
//  AuraServer
//
//  Created by ddorsat on 26.05.2026.
//

import Fluent
import Foundation

enum DailyContentKind: String, Codable {
    case insight
    case tip
}

final class DailyContent: Model, @unchecked Sendable {
    static let schema = "daily_contents"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "kind")
    var kind: String

    @Field(key: "text")
    var text: String

    @Field(key: "generated_date")
    var generatedDate: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil,
         userID: User.IDValue,
         kind: DailyContentKind,
         text: String,
         generatedDate: String) {
        self.id = id
        self.$user.id = userID
        self.kind = kind.rawValue
        self.text = text
        self.generatedDate = generatedDate
    }
}
