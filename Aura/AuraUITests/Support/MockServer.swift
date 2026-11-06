//
//  MockServer.swift
//  AuraUITests
//

import Foundation
import Network

// A small HTTP server inside the test process. The app talks to it instead of the real server,
// so the answers are always the same. It is plumbing: to write a test you only need respond(route:status:body:).
final class MockServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "aura.mock-server")
    private let lock = NSLock()
    private var responses: [String: (status: Int, body: Data)] = [:]
    private var receivedRequests: [String] = []
    private var receivedIdempotencyKeys: [String] = []

    init() throws {
        listener = try NWListener(using: .tcp, on: .any)

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            connection.start(queue: queue)
            receive(connection: connection, buffer: Data())
        }

        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            switch state {
                case .ready, .failed, .cancelled:
                    ready.signal()
                default:
                    break
            }
        }
        listener.start(queue: queue)

        guard ready.wait(timeout: .now() + 5) == .success, case .ready = listener.state else {
            listener.cancel()
            throw MockServerError.startupFailed
        }
    }

    var baseURL: String {
        "http://127.0.0.1:\(listener.port?.rawValue ?? 0)"
    }

    var requests: [String] {
        lock.withLock { receivedRequests }
    }

    var idempotencyKeys: [String] {
        lock.withLock { receivedIdempotencyKeys }
    }

    func respond(route: String, status: Int = 200, body: Data = Data()) {
        lock.withLock { responses[route] = (status, body) }
    }

    func stop() {
        listener.cancel()
    }

    private func receive(connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, _ in
            guard let self else { return }

            let buffer = buffer + (data ?? Data())

            guard let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) else {
                if !isComplete { receive(connection: connection, buffer: buffer) }
                return
            }

            let header = String(decoding: buffer[..<headerEnd.lowerBound], as: UTF8.self)
            let lines = header.split(separator: "\r\n")
            let contentLength = lines
                .first { $0.lowercased().hasPrefix("content-length:") }
                .flatMap { Int($0.split(separator: ":")[1].trimmingCharacters(in: .whitespaces)) } ?? 0

            guard buffer.count - headerEnd.upperBound >= contentLength else {
                receive(connection: connection, buffer: buffer)
                return
            }

            let idempotencyKey = lines
                .first { $0.lowercased().hasPrefix("idempotency-key:") }
                .flatMap { $0.split(separator: ":", maxSplits: 1).last }
                .map { $0.trimmingCharacters(in: .whitespaces) }

            answer(connection, requestLine: lines.first.map(String.init) ?? "", idempotencyKey: idempotencyKey)
        }
    }

    private func answer(_ connection: NWConnection, requestLine: String, idempotencyKey: String?) {
        let route = route(requestLine: requestLine)
        let (status, body) = lock.withLock { () -> (Int, Data) in
            self.receivedRequests.append(route)
            if let idempotencyKey {
                self.receivedIdempotencyKeys.append(idempotencyKey)
            }
            return self.responses[route] ?? (404, Data(#"{"error":true,"reason":"Не найдено"}"#.utf8))
        }

        var response = Data("HTTP/1.1 \(status) OK\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n".utf8)
        response.append(body)

        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    // The id in a path becomes :historyID, so a route can be answered without knowing the id
    private func route(requestLine: String) -> String {
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return requestLine }

        let path = parts[1]
            .split(separator: "/")
            .map { UUID(uuidString: String($0)) == nil ? String($0) : ":historyID" }
            .joined(separator: "/")

        return "\(parts[0]) /\(path)"
    }
}

private enum MockServerError: Error {
    case startupFailed
}
