import Fluent
import Vapor

func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.configureDatabase()
    app.configureMigrations()
    try await app.autoMigrate()

    try routes(app)
}
