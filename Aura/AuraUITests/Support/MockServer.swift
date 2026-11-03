//
//  MockServer.swift
//  AuraUITests
//

import Foundation
import Network
import XCTest

enum ContractFile {
    static func data(_ name: String) throws -> Data {
        let folder = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Contract")

        return try Data(contentsOf: folder.appendingPathComponent(name))
    }

    static func object(_ name: String) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: try data(name)) as? [String: Any])
    }
}

// A small HTTP server inside the test process. The app talks to it instead of the real backend.
final class MockServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "aura.mock-server")
    private let lock = NSLock()
    private let knownRoutes: Set<String>
    private var responses: [String: (status: Int, body: Data)] = [:]
    private var receivedRequests: [String] = []

    init() throws {
        knownRoutes = Set(try JSONDecoder().decode([String].self, from: try ContractFile.data("routes.json")))
        listener = try NWListener(using: .tcp, on: .any)

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            connection.start(queue: queue)
            receive(from: connection, buffer: Data())
        }

        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state { ready.signal() }
        }
        listener.start(queue: queue)
        ready.wait()
    }

    var baseURL: String {
        "http://127.0.0.1:\(listener.port?.rawValue ?? 0)"
    }

    var requests: [String] {
        lock.withLock { receivedRequests }
    }

    func respond(to route: String,
                 status: Int = 200,
                 body: Data = Data(),
                 file: StaticString = #filePath,
                 line: UInt = #line) {
        XCTAssertTrue(knownRoutes.contains(route), "\(route) is not in Contract/routes.json", file: file, line: line)
        lock.withLock { responses[route] = (status, body) }
    }

    func stop() {
        listener.cancel()
    }

    private func receive(from connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, _ in
            guard let self else { return }

            let buffer = buffer + (data ?? Data())

            guard let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) else {
                if !isComplete { receive(from: connection, buffer: buffer) }
                return
            }

            let header = String(decoding: buffer[..<headerEnd.lowerBound], as: UTF8.self)
            let lines = header.split(separator: "\r\n")
            let contentLength = lines
                .first { $0.lowercased().hasPrefix("content-length:") }
                .flatMap { Int($0.split(separator: ":")[1].trimmingCharacters(in: .whitespaces)) } ?? 0

            guard buffer.count - headerEnd.upperBound >= contentLength else {
                receive(from: connection, buffer: buffer)
                return
            }

            answer(connection, requestLine: lines.first.map(String.init) ?? "")
        }
    }

    private func answer(_ connection: NWConnection, requestLine: String) {
        let route = route(from: requestLine)
        let (status, body) = lock.withLock { () -> (Int, Data) in
            self.receivedRequests.append(route)
            return self.responses[route] ?? (404, Data(#"{"error":true,"reason":"Не найдено"}"#.utf8))
        }

        var response = Data("HTTP/1.1 \(status) OK\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n".utf8)
        response.append(body)

        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    // The id in a path becomes the name from Contract/routes.json
    private func route(from requestLine: String) -> String {
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return requestLine }

        let path = parts[1]
            .split(separator: "/")
            .map { UUID(uuidString: String($0)) == nil ? String($0) : ":historyID" }
            .joined(separator: "/")

        return "\(parts[0]) /\(path)"
    }
}
