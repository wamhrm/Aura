import Fluent
import Vapor

func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

    try app.configureDatabase()
    app.configureMigrations()
    try await app.autoMigrate()

    try routes(app)
}
