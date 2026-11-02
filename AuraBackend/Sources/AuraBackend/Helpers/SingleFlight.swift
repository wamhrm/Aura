//
//  SingleFlight.swift
//  AuraBackend
//
//  Created by wamhrm on 02.11.2026.
//

// Joins parallel requests for the same key into one operation. Works within one server instance.
actor SingleFlight {
    static let shared = SingleFlight()

    private var tasks: [String: Task<any Sendable, any Error>] = [:]

    func run<Value: Sendable>(key: String,
                              operation: @escaping @Sendable () async throws -> Value) async throws -> Value {
        let task: Task<any Sendable, any Error>

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

        guard let value = try await task.value as? Value else {
            preconditionFailure("SingleFlight key '\(key)' is used with different value types")
        }

        return value
    }
}
