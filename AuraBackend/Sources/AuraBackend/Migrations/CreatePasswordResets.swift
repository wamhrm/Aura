//
//  CreatePasswordResets.swift
//  AuraBackend
//
//  Created by ddorsat on 27.10.2026.
//

import Fluent

struct CreatePasswordResets: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PasswordReset.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("code_hash", .string, .required)
            .field("expires_at", .datetime, .required)
            .field("attempts", .int, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PasswordReset.schema).delete()
    }
}
