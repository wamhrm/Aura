import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    try app.register(collection: AdminController())
    try app.register(collection: ProfileController())
    try app.register(collection: HistoryController())
    try app.register(collection: PsychologyController())
    try app.register(collection: HoroscopeController())
}
