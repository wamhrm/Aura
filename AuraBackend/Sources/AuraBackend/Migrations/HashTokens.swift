//
//  HashTokens.swift
//  AuraBackend
//
//  Created by ddorsat on 20.10.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct HashTokens: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(Token.schema)
                .field("expires_at", .datetime)
                .update()

            try await transaction.sql().raw("""
                UPDATE tokens
                SET value = encode(sha256(convert_to(value, 'UTF8')), 'hex'),
                    expires_at = \(bind: Date().addingTimeInterval(Token.lifetime))
                """).run()

            try await transaction.sql().raw("ALTER TABLE tokens ALTER COLUMN expires_at SET NOT NULL").run()

            try await transaction.schema(Token.schema)
                .unique(on: "value")
                .update()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.sql().raw("DELETE FROM tokens").run()

            try await transaction.schema(Token.schema)
                .deleteUnique(on: "value")
                .deleteField("expires_at")
                .update()
        }
    }
}
