//
//  CreateHistory.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent

struct CreateHistory: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(History.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("kind", .string, .required)
            .field("created_at", .datetime)
            .field("selected_tests", .array(of: .string), .required)
            .field("result", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(History.schema).delete()
    }
}
