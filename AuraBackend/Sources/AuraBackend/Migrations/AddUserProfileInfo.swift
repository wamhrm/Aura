import Fluent

struct AddUserProfileInfo: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .field("birth_time", .string)
            .field("gender", .string)
            .field("social_type", .string)
            .field("conflict_style", .string)
            .field("emotional_core", .string)
            .field("decision_style", .string)
            .field("core_focus", .string)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(User.schema)
            .deleteField("birth_time")
            .deleteField("gender")
            .deleteField("social_type")
            .deleteField("conflict_style")
            .deleteField("emotional_core")
            .deleteField("decision_style")
            .deleteField("core_focus")
            .update()
    }
}
