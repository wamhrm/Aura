import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    try app.register(collection: ProfileController())
    try app.register(collection: PersonalityController())
    try app.register(collection: AdminController())
}
