//
//  Application+Database.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import FluentPostgresDriver
import Foundation
import NIOSSL
import SQLKit
import Vapor

extension Application {
    func configureDatabase() throws {
        guard let hostname = Environment.get("POSTGRESQL_HOST"),
              let username = Environment.get("POSTGRESQL_USER"),
              let password = Environment.get("POSTGRESQL_PASSWORD"),
              let database = Environment.get("POSTGRESQL_DBNAME") else {
            throw Abort(.internalServerError, reason: "Invalid DB credentials")
        }

        let port = Int(Environment.get("POSTGRESQL_PORT") ?? "5432") ?? 5432
        let tls = try databaseTLSConfiguration()

        let dbConfig = SQLPostgresConfiguration(hostname: hostname,
                                                port: port,
                                                username: username,
                                                password: password,
                                                database: database,
                                                tls: tls)

        self.databases.use(.postgres(configuration: dbConfig), as: .psql)
    }

    private func databaseTLSConfiguration() throws -> PostgresConnection.Configuration.TLS {
        let certPath = Environment.get("POSTGRESQL_CA_CERT_PATH") ?? Environment.get("POSTGRESQL_SSL_ROOT_CERT")

        guard let certPath, !certPath.isEmpty else {
            guard environment != .production else {
                throw Abort(.internalServerError, reason: "PostgreSQL CA certificate is required in production")
            }
            return .disable
        }

        guard FileManager.default.isReadableFile(atPath: certPath) else {
            throw Abort(.internalServerError, reason: "PostgreSQL CA certificate is not readable at the configured path")
        }

        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.trustRoots = .file(certPath)
        tlsConfig.certificateVerification = .fullVerification
        
        return try .require(NIOSSLContext(configuration: tlsConfig))
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
