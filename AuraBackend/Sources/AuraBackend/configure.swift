import Fluent
import Vapor

func configure(_ app: Application) async throws {
    try app.validateEnvironment()

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

    app.middleware = Middlewares()
    app.middleware.use(RequestLoggingMiddleware())
    app.middleware.use(AppErrorMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.configureDatabase()
    app.configureMigrations()

    try routes(app)
}
