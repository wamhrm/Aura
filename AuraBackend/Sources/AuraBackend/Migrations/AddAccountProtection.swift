//
//  AddAccountProtection.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct AddAccountProtection: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(User.schema)
                .field("email_confirmed_at", .datetime)
                .field("sign_in_attempts", .int, .required, .sql(.default(0)))
                .field("sign_in_window_start", .datetime)
                .update()

            try await transaction.schema(EmailConfirmation.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("code_hash", .string, .required)
                .field("expires_at", .datetime, .required)
                .field("attempts", .int, .required)
                .field("created_at", .datetime)
                .create()

            try await transaction.sql()
                .raw("CREATE INDEX email_confirmations_user_id_idx ON email_confirmations (user_id)")
                .run()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(EmailConfirmation.schema).delete()

            try await transaction.schema(User.schema)
                .deleteField("email_confirmed_at")
                .deleteField("sign_in_attempts")
                .deleteField("sign_in_window_start")
                .update()
        }
    }
}
