import Vapor

func configure(app: Application) async throws {
    await DotEnvFile.load(path: ".env.local", fileio: app.fileio, logger: app.logger)
    try app.validateEnvironment()

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

    app.middleware = Middlewares()
    app.middleware.use(AppRouteLoggingMiddleware())
    app.middleware.use(AppErrorMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.configureDatabase()
    app.configureMigrations()

    try routes(app: app)
}

private struct AppRouteLoggingMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        req.logger.info("\(req.route?.description ?? "unmatched route")")
        return try await next.respond(to: req)
    }
}
