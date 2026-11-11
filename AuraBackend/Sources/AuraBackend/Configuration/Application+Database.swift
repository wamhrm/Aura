//
//  Application+Database.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import FluentPostgresDriver
import SQLKit
import Vapor

extension Application {
    func configureDatabase() throws {
        guard let databaseURL = postgresURL() else {
            throw Abort(.internalServerError, reason: "Invalid DB credentials")
        }

        let dbConfig = try SQLPostgresConfiguration(url: databaseURL)
        self.databases.use(.postgres(configuration: dbConfig), as: .psql)
    }

    private func postgresURL() -> String? {
        let unpooled = Environment.get("DATABASE_URL_UNPOOLED") ?? ""
        if !unpooled.isEmpty {
            return unpooled
        }
        let pooled = Environment.get("DATABASE_URL") ?? ""
        return pooled.isEmpty ? nil : pooled
    }
}

extension Database {
    func sql() throws -> any SQLDatabase {
        guard let sql = self as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "SQL database required")
        }
        return sql
    }

    func generationLock<T: Sendable>(_ name: String,
                                     perform operation: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await transaction { database in
            try await database.sql().raw("SELECT pg_advisory_xact_lock(hashtext(\(bind: name)), 0)").run()
            return try await operation(database)
        }
    }
}
