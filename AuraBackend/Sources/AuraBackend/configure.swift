import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import JWT
import Vapor

public func configure(_ app: Application) async throws {
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        let databaseHost = Environment.get("POSTGRESQL_HOST") ?? "localhost"
        let databasePort = Environment.get("POSTGRESQL_PORT")
            .flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber
        let databaseUsername = Environment.get("POSTGRESQL_USER") ?? "vapor_username"
        let databasePassword = Environment.get("POSTGRESQL_PASSWORD") ?? "vapor_password"
        let databaseName = Environment.get("POSTGRESQL_DBNAME") ?? "vapor_database"
        let databaseTLSConfiguration = makeDatabaseTLSConfiguration()

        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: databaseHost,
            port: databasePort,
            username: databaseUsername,
            password: databasePassword,
            database: databaseName,
            tls: try .require(.init(configuration: databaseTLSConfiguration)))), as: .psql)
    }

    let jwtSecret = Environment.get("JWT_SECRET") ?? "aura-local-development-secret"
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

    app.migrations.add(CreateUser())
    app.migrations.add(AddUserProfileInfo())
    try routes(app)
}

private func makeDatabaseTLSConfiguration() -> TLSConfiguration {
    var configuration = TLSConfiguration.makeClientConfiguration()

    if let rootCertificatePath = Environment.get("POSTGRESQL_SSL_ROOT_CERT") {
        configuration.trustRoots = .file(rootCertificatePath)
    }

    return configuration
}
