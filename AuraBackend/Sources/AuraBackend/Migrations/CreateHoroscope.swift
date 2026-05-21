//
//  CreateHoroscope.swift
//  AuraServer
//
//  Created by ddorsat on 21.05.2026.
//

import Fluent

struct CreateHoroscope: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Horoscope.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .unique(on: "user_id")
            .field("sign", .string, .required)
            .field("date_start", .string, .required)
            .field("date_end", .string, .required)
            .field("description", .string, .required)
            .field("items", .json)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Horoscope.schema).delete()
    }
}
