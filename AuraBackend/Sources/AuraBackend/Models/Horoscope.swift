//
//  Horoscope.swift
//  AuraServer
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Foundation

final class Horoscope: Model, @unchecked Sendable {
    static let schema = "horoscopes"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "sign")
    var sign: String

    @Field(key: "date_start")
    var dateStart: String

    @Field(key: "date_end")
    var dateEnd: String

    @Field(key: "description")
    var description: String

    @Field(key: "items")
    var items: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil,
         userID: User.IDValue,
         sign: String,
         dateStart: String,
         dateEnd: String,
         description: String,
         itemsJSON: String) {
        self.id = id
        self.$user.id = userID
        self.sign = sign
        self.dateStart = dateStart
        self.dateEnd = dateEnd
        self.description = description
        self.items = itemsJSON
    }
}
