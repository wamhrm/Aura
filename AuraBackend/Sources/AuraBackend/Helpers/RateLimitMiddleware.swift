//
//  RateLimitMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 20.10.2026.
//

import Vapor

struct RateLimitMiddleware: AsyncMiddleware {
    private let limiter: RateLimiter

    init(limit: Int, window: TimeInterval) {
        self.limiter = RateLimiter(limit: limit, window: window)
    }

    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard await limiter.allow(clientIP(of: req)) else {
            throw Abort(.tooManyRequests, reason: "Слишком много попыток. Попробуйте позже")
        }

        return try await next.respond(to: req)
    }

    private func clientIP(of req: Request) -> String {
        if let ip = req.headers.first(name: "CF-Connecting-IP") {
            return ip
        }

        if let forwarded = req.headers.first(name: .xForwardedFor),
           let ip = forwarded.split(separator: ",").first {
            return ip.trimmingCharacters(in: .whitespaces)
        }

        return req.remoteAddress?.ipAddress ?? "unknown"
    }
}

private actor RateLimiter {
    private let limit: Int
    private let window: TimeInterval
    private let maxTrackedKeys = 10_000
    private var buckets: [String: (start: Date, count: Int)] = [:]

    init(limit: Int, window: TimeInterval) {
        self.limit = limit
        self.window = window
    }

    func allow(_ key: String) -> Bool {
        let now = Date()

        if buckets.count > maxTrackedKeys {
            buckets = buckets.filter { now.timeIntervalSince($0.value.start) < window }
        }

        guard let bucket = buckets[key], now.timeIntervalSince(bucket.start) < window else {
            buckets[key] = (now, 1)
            return true
        }

        guard bucket.count < limit else { return false }

        buckets[key] = (bucket.start, bucket.count + 1)
        return true
    }
}
