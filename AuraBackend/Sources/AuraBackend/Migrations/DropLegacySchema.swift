//
//  DropLegacySchema.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

// Removes the pre-release schema with all its test data. Delete this file after the first deploy.
struct DropLegacySchema: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.sql()
                .raw("DROP TABLE IF EXISTS password_resets, test_usages, daily_contents, horoscopes, history, tokens, users CASCADE")
                .run()
            try await transaction.sql().raw("DELETE FROM _fluent_migrations").run()
        }
    }

    func revert(on database: any Database) async throws {}
}
