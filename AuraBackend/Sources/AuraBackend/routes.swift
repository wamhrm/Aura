import Vapor

func routes(app: Application) throws {
    // Migrations finish before HTTP starts; a short database failure does not restart the server
    app.get("health") { _ -> HTTPStatus in
        .ok
    }

    // For an uptime monitor: the database answers right now
    app.get("ready") { req -> HTTPStatus in
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
