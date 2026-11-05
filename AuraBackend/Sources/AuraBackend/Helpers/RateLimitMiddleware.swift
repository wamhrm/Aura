//
//  RateLimitMiddleware.swift
//  AuraBackend
//
//  Created by wamhrm on 20.10.2026.
//

import NIOCore
import Vapor

struct RateLimitMiddleware: AsyncMiddleware {
    private let limiter: RateLimiter

    init(limit: Int, window: TimeInterval) {
        self.limiter = RateLimiter(limit: limit, window: window)
    }

    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard await limiter.allow(key: clientIP(req: req)) else {
            throw Abort(.tooManyRequests, reason: "Слишком много попыток. Попробуйте позже")
        }

        return try await next.respond(to: req)
    }

    // Render routes public requests through Cloudflare. Other hosts must not trust this header by default.
    private func clientIP(req: Request) -> String {
        let remoteIP = req.remoteAddress?.ipAddress ?? "unknown"
        let values = req.headers["CF-Connecting-IP"]

        guard Environment.get("RENDER") == "true",
              values.count == 1,
              let address = try? SocketAddress(ipAddress: values[0], port: 0),
              let ip = address.ipAddress else { return remoteIP }

        return ip
    }
}

private actor RateLimiter {
    private let limit: Int
    private let window: TimeInterval
    private let maxTrackedKeys = 10_000
    private var buckets: [String: (start: Date, count: Int)] = [:]
    private var lastCleanup = Date()

    init(limit: Int, window: TimeInterval) {
        self.limit = limit
        self.window = window
    }

    func allow(key: String) -> Bool {
        let now = Date()

        if now.timeIntervalSince(lastCleanup) >= window {
            buckets = buckets.filter { now.timeIntervalSince($0.value.start) < window }
            lastCleanup = now
        }

        guard let bucket = buckets[key], now.timeIntervalSince(bucket.start) < window else {
            guard buckets[key] != nil || buckets.count < maxTrackedKeys else { return false }
            buckets[key] = (now, 1)
            return true
        }

        guard bucket.count < limit else { return false }

        buckets[key] = (bucket.start, bucket.count + 1)
        return true
    }
}
