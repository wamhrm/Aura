//
//  AppVersionMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

// Without MIN_APP_VERSION every version is allowed
struct AppVersionMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        if let minimum = Environment.get("MIN_APP_VERSION"), !minimum.isEmpty,
           !isSupported(req.headers.first(name: "X-App-Version"), minimum: minimum) {
            throw Abort(.upgradeRequired, reason: "Обновите приложение, чтобы продолжить")
        }

        return try await next.respond(to: req)
    }

    // Compared by numbers: 1.10 is newer than 1.9, and 1.0 equals 1.0.0
    private func isSupported(_ version: String?, minimum: String) -> Bool {
        guard let version else { return false }

        let current = numbers(in: version)
        let required = numbers(in: minimum)

        for index in 0..<max(current.count, required.count) {
            let currentNumber = index < current.count ? current[index] : 0
            let requiredNumber = index < required.count ? required[index] : 0

            if currentNumber != requiredNumber {
                return currentNumber > requiredNumber
            }
        }

        return true
    }

    private func numbers(in version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }
}
