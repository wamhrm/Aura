//
//  SingleFlight.swift
//  AuraBackend
//
//  Created by wamhrm on 02.11.2026.
//

// Joins parallel requests for the same key into one operation. Works within one server instance.
actor SingleFlight<Value: Sendable> {
    private var tasks: [String: Task<Value, any Error>] = [:]

    func run(key: String,
             operation: @escaping @Sendable () async throws -> Value) async throws -> Value {
        let task: Task<Value, any Error>

        if let running = tasks[key] {
            task = running
        } else {
            task = Task { try await operation() }
            tasks[key] = task
        }

        defer {
            if tasks[key] == task {
                tasks[key] = nil
            }
        }

        return try await task.value
    }
}
