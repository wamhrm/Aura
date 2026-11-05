import Fluent
import Vapor

struct AddDailyGenerationProtection: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(DailyContent.schema)
                .deleteUnique(on: "user_id", "kind")
                .unique(on: "user_id", "kind", "generated_date")
                .update()

            try await transaction.schema(DailyGenerationAttempt.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("kind", .string, .required)
                .field("generated_date", .string, .required)
                .field("created_at", .datetime, .required)
                .field("finished_at", .datetime)
                .create()

            let sql = try transaction.sql()
            try await sql.raw("CREATE INDEX daily_attempts_user_kind_created_idx ON daily_generation_attempts (user_id, kind, created_at)").run()
            try await sql.raw("CREATE UNIQUE INDEX daily_attempts_running_idx ON daily_generation_attempts (user_id, kind, generated_date) WHERE finished_at IS NULL").run()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            let duplicates = try await transaction.sql().raw("SELECT 1 FROM daily_contents GROUP BY user_id, kind HAVING COUNT(*) > 1 LIMIT 1").all()
            guard duplicates.isEmpty else {
                throw Abort(.conflict, reason: "Cannot revert while daily content contains multiple dates per user and kind")
            }

            try await transaction.schema(DailyContent.schema)
                .deleteUnique(on: "user_id", "kind", "generated_date")
                .unique(on: "user_id", "kind")
                .update()
            try await transaction.schema(DailyGenerationAttempt.schema).delete()
        }
    }
}
