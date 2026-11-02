import Vapor

func routes(_ app: Application) throws {
    let v1 = app.grouped("v1").grouped(AppVersionMiddleware())

    try v1.register(collection: AuthController())
    try v1.register(collection: ProfileController())
    try v1.register(collection: HistoryController())
    try v1.register(collection: PsychologyController())
    try v1.register(collection: HoroscopeController())
    try v1.register(collection: DailyContentController())
}
