import Fluent
import FluentPostgresDriver
import Foundation
import NIOSSL
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

        guard let certPath, !certPath.isEmpty, FileManager.default.fileExists(atPath: certPath) else {
            return .disable
        }

        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.trustRoots = .file(certPath)
        tlsConfig.certificateVerification = .fullVerification
        return try .require(NIOSSLContext(configuration: tlsConfig))
    }
}
