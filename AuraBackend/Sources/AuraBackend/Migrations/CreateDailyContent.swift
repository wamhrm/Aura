//
//  CreateDailyContent.swift
//  AuraBackend
//
//  Created by ddorsat on 26.05.2026.
//

import Fluent

struct CreateDailyContent: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(DailyContent.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("kind", .string, .required)
            .field("text", .string, .required)
            .field("generated_date", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "user_id", "kind")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(DailyContent.schema).delete()
    }
}
