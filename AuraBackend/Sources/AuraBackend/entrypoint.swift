import Fluent
import Logging
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = try await Application.make(env)

        do {
            try await configure(app: app)

            if (env.commandInput.arguments.first ?? "serve") == "serve" {
                try await migrateOnStartup(app: app)
            }

            try await app.execute()
        } catch {
            app.logger.error("AuraBackend failed to run: \(errorLogCode(error))")
            try? await app.asyncShutdown()
            throw Abort(.internalServerError, reason: "AuraBackend failed to run")
        }
        try await app.asyncShutdown()
    }

    private static func migrateOnStartup(app: Application) async throws {
        app.logger.info("Preparing database migrations")
        let migrator = Migrator(databases: app.databases,
                                migrations: app.migrations,
                                logger: Logger(label: "AuraBackend.Migrations", factory: { _ in SwiftLogNoOpLogHandler() }),
                                on: app.eventLoopGroup.any())
        try await migrator.setupIfNeeded().get()
        try await migrator.prepareBatch().get()
    }
}
