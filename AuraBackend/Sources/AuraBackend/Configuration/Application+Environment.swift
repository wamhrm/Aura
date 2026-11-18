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

        var missing = ["OPENAI_KEY", "RESEND_API_KEY"].filter { !isSet(name: $0) }
        if !isSet(name: "DATABASE_URL") && !isSet(name: "DATABASE_URL_UNPOOLED") {
            missing.append("DATABASE_URL_UNPOOLED")
        }

        guard missing.isEmpty else {
            let reason = "Set these environment variables: \(missing.joined(separator: ", "))"
            logger.error("\(reason)")
            throw Abort(.internalServerError, reason: reason)
        }
    }

    private func isSet(name: String) -> Bool {
        !(Environment.get(name) ?? "").isEmpty
    }
}
