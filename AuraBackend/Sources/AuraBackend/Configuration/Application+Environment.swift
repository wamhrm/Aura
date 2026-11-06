//
//  Application+Environment.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

extension Application {
    // A production server without these can't do its work, so it stops at launch with a clear message
    func validateEnvironment() throws {
        guard environment == .production else { return }

        var required = ["POSTGRESQL_HOST", "POSTGRESQL_USER", "POSTGRESQL_PASSWORD", "POSTGRESQL_DBNAME", "OPENAI_KEY", "RESEND_API_KEY"]

        if isSet(name: "APPLE_PRIVATE_KEY") {
            required.append("APPLE_TOKEN_ENCRYPTION_KEY")
        } else {
            logger.warning("Sign in with Apple is not fully configured: APPLE_PRIVATE_KEY is missing")
        }

        let missing = required.filter { !isSet(name: $0) }

        guard missing.isEmpty else {
            throw Abort(.internalServerError, reason: "Set these environment variables: \(missing.joined(separator: ", "))")
        }
    }

    private func isSet(name: String) -> Bool {
        !(Environment.get(name) ?? "").isEmpty
    }
}
