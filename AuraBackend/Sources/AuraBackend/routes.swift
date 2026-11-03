import Vapor

func routes(_ app: Application) throws {
    // For the host: the server is up and the database schema is ready, a short database failure does not restart it
    app.get("health") { req -> HTTPStatus in
        req.application.hasFinishedMigrations ? .ok : .serviceUnavailable
    }

    // For an uptime monitor: the database answers right now
    app.get("ready") { req -> HTTPStatus in
        guard req.application.hasFinishedMigrations else { return .serviceUnavailable }

        do {
            try await req.db.sql().raw("SELECT 1").run()
            return .ok
        } catch {
            req.logger.error("Database check failed: \(error)")
            return .serviceUnavailable
        }
    }

    let v1 = app.grouped("v1").grouped(AppVersionMiddleware())

    try v1.register(collection: AuthController())
    try v1.register(collection: ProfileController())
    try v1.register(collection: HistoryController())
    try v1.register(collection: PsychologyController())
    try v1.register(collection: HoroscopeController())
    try v1.register(collection: DailyContentController())
}
