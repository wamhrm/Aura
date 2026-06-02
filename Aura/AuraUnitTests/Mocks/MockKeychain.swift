//
//  MockKeychain.swift
//  AuraUnitTests
//

import Foundation
@testable import Aura

nonisolated final class MockKeychain: KeychainHelperProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var token: Data?

    init(token: Data? = nil) {
        self.token = token
    }

    func saveToken(_ data: Data, path: String, key: String) {
        lock.withLock { token = data }
    }

    func getToken(path: String, key: String) -> Data? {
        lock.withLock { token }
    }

    func deleteToken(path: String, key: String) {
        lock.withLock { token = nil }
    }
}
