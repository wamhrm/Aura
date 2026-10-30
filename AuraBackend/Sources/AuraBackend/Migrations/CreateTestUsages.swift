//
//  CreateTestUsages.swift
//  AuraBackend
//
//  Created by wamhrm on 21.10.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct CreateTestUsages: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(TestUsage.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("created_at", .datetime)
                .create()

            try await transaction.sql()
                .raw("CREATE INDEX IF NOT EXISTS test_usages_user_id_created_at_idx ON test_usages (user_id, created_at)")
                .run()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.schema(TestUsage.schema).delete()
    }
}
