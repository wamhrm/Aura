//
//  CreateSchema.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct CreateSchema: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(User.schema)
                .id()
                .field("name", .string, .required)
                .field("email", .string)
                .field("password_hash", .string)
                .field("apple_user_id", .string)
                .field("apple_refresh_token", .string)
                .field("date_of_birth", .datetime)
                .field("birth_time", .string)
                .field("gender", .string)
                .field("social_type", .string)
                .field("conflict_style", .string)
                .field("emotional_core", .string)
                .field("decision_style", .string)
                .field("core_focus", .string)
                .field("ai_consent_at", .datetime)
                .field("created_at", .datetime)
                .unique(on: "email")
                .unique(on: "apple_user_id")
                .create()

            try await transaction.schema(Token.schema)
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("expires_at", .datetime, .required)
                .unique(on: "value")
                .create()

            try await transaction.schema(History.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("request_id", .uuid, .required)
                .field("kind", .string, .required)
                .field("created_at", .datetime)
                .field("selected_tests", .array(of: .string), .required)
                .field("title", .string, .required)
                .field("subtitle", .string, .required)
                .field("zodiac_sign", .string, .required)
                .field("compatibility_score", .int)
                .field("partner_name", .string)
                .field("partner_zodiac_sign", .string)
                .field("result", .string, .required)
                .unique(on: "user_id", "request_id")
                .create()

            try await transaction.schema(Horoscope.schema)
                .id()
                .field("sign", .string, .required)
                .field("week_start", .string, .required)
                .field("date_start", .string, .required)
                .field("date_end", .string, .required)
                .field("description", .string, .required)
                .field("items", .string, .required)
                .field("created_at", .datetime)
                .unique(on: "sign", "week_start")
                .create()

            try await transaction.schema(DailyContent.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("kind", .string, .required)
                .field("text", .string, .required)
                .field("generated_date", .string, .required)
                .field("created_at", .datetime)
                .unique(on: "user_id", "kind")
                .create()

            try await transaction.schema(TestUsage.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("created_at", .datetime)
                .create()

            try await transaction.schema(PasswordReset.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("code_hash", .string, .required)
                .field("expires_at", .datetime, .required)
                .field("attempts", .int, .required)
                .field("created_at", .datetime)
                .create()

            let sql = try transaction.sql()

            try await sql.raw("CREATE INDEX tokens_user_id_idx ON tokens (user_id)").run()
            try await sql.raw("CREATE INDEX history_user_id_created_at_idx ON history (user_id, created_at DESC)").run()
            try await sql.raw("CREATE INDEX test_usages_user_id_created_at_idx ON test_usages (user_id, created_at)").run()
            try await sql.raw("CREATE INDEX password_resets_user_id_idx ON password_resets (user_id)").run()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(PasswordReset.schema).delete()
            try await transaction.schema(TestUsage.schema).delete()
            try await transaction.schema(DailyContent.schema).delete()
            try await transaction.schema(Horoscope.schema).delete()
            try await transaction.schema(History.schema).delete()
            try await transaction.schema(Token.schema).delete()
            try await transaction.schema(User.schema).delete()
        }
    }
}
