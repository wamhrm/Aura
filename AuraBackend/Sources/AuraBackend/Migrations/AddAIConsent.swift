//
//  AddAIConsent.swift
//  AuraBackend
//
//  Created by wamhrm on 23.10.2026.
//

import Fluent

struct AddAIConsent: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .field("ai_consent_at", .datetime)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(User.schema)
            .deleteField("ai_consent_at")
            .update()
    }
}
