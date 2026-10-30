//
//  AddAppleSignIn.swift
//  AuraBackend
//
//  Created by wamhrm on 25.10.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct AddAppleSignIn: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(User.schema)
                .field("apple_user_id", .string)
                .field("apple_refresh_token", .string)
                .unique(on: "apple_user_id")
                .update()

            try await transaction.sql().raw("ALTER TABLE users ALTER COLUMN email DROP NOT NULL").run()
            try await transaction.sql().raw("ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL").run()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.sql().raw("DELETE FROM users WHERE email IS NULL OR password_hash IS NULL").run()
            try await transaction.sql().raw("ALTER TABLE users ALTER COLUMN email SET NOT NULL").run()
            try await transaction.sql().raw("ALTER TABLE users ALTER COLUMN password_hash SET NOT NULL").run()

            try await transaction.schema(User.schema)
                .deleteUnique(on: "apple_user_id")
                .deleteField("apple_user_id")
                .deleteField("apple_refresh_token")
                .update()
        }
    }
}
