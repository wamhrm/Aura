//
//  DataCleanupService.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Fluent
import Vapor

// The privacy policy promises how long these records live, also for users who never come back
struct DataCleanupService {
    private let recordLifetime: TimeInterval = 24 * 60 * 60

    func run(on database: any Database) async throws {
        let oldestAllowed = Date().addingTimeInterval(-recordLifetime)

        try await Token.query(on: database).filter(\.$expiresAt < Date()).delete()
        try await PasswordReset.query(on: database).filter(\.$createdAt < oldestAllowed).delete()
        try await EmailConfirmation.query(on: database).filter(\.$createdAt < oldestAllowed).delete()
        try await TestUsage.query(on: database).filter(\.$createdAt < oldestAllowed).delete()
    }
}
