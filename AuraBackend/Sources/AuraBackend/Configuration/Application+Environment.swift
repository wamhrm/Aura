//
//  Application+Environment.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

extension Application {
    func validateEnvironment() throws {
        guard environment == .production else { return }

        let required = ["POSTGRESQL_HOST",
                        "POSTGRESQL_USER",
                        "POSTGRESQL_PASSWORD",
                        "POSTGRESQL_DBNAME",
                        "OPENAI_KEY",
                        "RESEND_API_KEY"]
        let missing = required.filter { !isSet(name: $0) }

        guard missing.isEmpty else {
            throw Abort(.internalServerError, reason: "Set these environment variables: \(missing.joined(separator: ", "))")
        }
    }

    private func isSet(name: String) -> Bool {
        !(Environment.get(name) ?? "").isEmpty
    }
}
