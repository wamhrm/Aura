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
                try await app.autoMigrate()
            }

            try await app.execute()
        } catch {
            app.logger.error("AuraBackend failed to run: \(errorLogCode(error))")
            try? await app.asyncShutdown()
            throw Abort(.internalServerError, reason: "AuraBackend failed to run")
        }
        try await app.asyncShutdown()
    }
}
