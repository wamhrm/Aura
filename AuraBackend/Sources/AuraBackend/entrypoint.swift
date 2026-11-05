import Logging
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = try await Application.make(env)
        var cleanupTask: Task<Void, Never>?

        do {
            try await configure(app: app)

            // Commands like `migrate` do their own work
            if (env.commandInput.arguments.first ?? "serve") == "serve" {
                try await app.autoMigrate()
                cleanupTask = app.startDataCleanup()
            }

            try await app.execute()
        } catch {
            app.logger.report(error: error)
            cleanupTask?.cancel()
            await cleanupTask?.value
            try? await app.asyncShutdown()
            throw error
        }
        cleanupTask?.cancel()
        await cleanupTask?.value
        try await app.asyncShutdown()
    }
}
