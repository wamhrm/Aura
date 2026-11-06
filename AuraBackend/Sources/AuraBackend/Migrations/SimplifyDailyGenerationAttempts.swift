//
//  SimplifyDailyGenerationAttempts.swift
//  AuraBackend
//
//  Created by wamhrm on 06.11.2026.
//

import Fluent

struct SimplifyDailyGenerationAttempts: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.sql().raw("DROP INDEX daily_attempts_running_idx").run()
            try await transaction.schema(DailyGenerationAttempt.schema)
                .deleteField("finished_at")
                .update()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(DailyGenerationAttempt.schema)
                .field("finished_at", .datetime)
                .update()

            // Execution status is no longer stored; preserve existing attempts as completed on rollback.
            try await transaction.sql().raw("UPDATE daily_generation_attempts SET finished_at = created_at").run()
            try await transaction.sql().raw("CREATE UNIQUE INDEX daily_attempts_running_idx ON daily_generation_attempts (user_id, kind, generated_date) WHERE finished_at IS NULL").run()
        }
    }
}
