//
//  CreateSharedHoroscopes.swift
//  AuraBackend
//
//  Created by ddorsat on 21.10.2026.
//

import Fluent

struct CreateSharedHoroscopes: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(Horoscope.schema).delete()

            try await transaction.schema(Horoscope.schema)
                .id()
                .field("sign", .string, .required)
                .field("week_start", .string, .required)
                .field("date_start", .string, .required)
                .field("date_end", .string, .required)
                .field("description", .string, .required)
                .field("items", .string, .required)
                .field("created_at", .datetime)
                .unique(on: "sign", "week_start")
                .create()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { transaction in
            try await transaction.schema(Horoscope.schema).delete()
            try await CreateHoroscope().prepare(on: transaction)
        }
    }
}
