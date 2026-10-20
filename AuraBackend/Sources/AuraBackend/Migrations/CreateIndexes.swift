//
//  CreateIndexes.swift
//  AuraBackend
//
//  Created by ddorsat on 21.10.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct CreateIndexes: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let sql = try database.sql()

        try await sql.raw("CREATE INDEX IF NOT EXISTS tokens_user_id_idx ON tokens (user_id)").run()
        try await sql.raw("CREATE INDEX IF NOT EXISTS history_user_id_created_at_idx ON history (user_id, created_at DESC)").run()
    }

    func revert(on database: any Database) async throws {
        let sql = try database.sql()

        try await sql.raw("DROP INDEX IF EXISTS tokens_user_id_idx").run()
        try await sql.raw("DROP INDEX IF EXISTS history_user_id_created_at_idx").run()
    }
}
