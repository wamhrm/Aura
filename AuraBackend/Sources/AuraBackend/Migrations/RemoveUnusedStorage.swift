//
//  RemoveUnusedStorage.swift
//  AuraBackend
//
//  Created by wamhrm on 10.11.2026.
//

import Fluent
import Vapor

struct RemoveUnusedStorage: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(DailyGenerationAttempt.schema).delete()

            try await transaction.schema(User.schema)
                .deleteUnique(on: "apple_user_id")
                .deleteField("apple_user_id")
                .deleteField("apple_refresh_token")
                .deleteField("sign_in_attempts")
                .deleteField("sign_in_window_start")
                .update()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(User.schema)
                .field("apple_user_id", .string)
                .field("apple_refresh_token", .string)
                .field("sign_in_attempts", .int, .required, .sql(.default(0)))
                .field("sign_in_window_start", .datetime)
                .unique(on: "apple_user_id")
                .update()

            try await transaction.schema(DailyGenerationAttempt.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("kind", .string, .required)
                .field("generated_date", .string, .required)
                .field("created_at", .datetime, .required)
                .create()

            try await transaction.sql()
                .raw("CREATE INDEX daily_attempts_user_kind_created_idx ON daily_generation_attempts (user_id, kind, created_at)")
                .run()
        }
    }
}
