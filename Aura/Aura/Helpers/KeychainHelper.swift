//  KeychainHelper.swift
//  Aura
//
//  Created by wamhrm on 05.04.2026.
//

import Foundation
import os
import Security

nonisolated protocol KeychainHelperProtocol: Sendable {
    func saveToken(_ data: Data, path: String, key: String)
    func getToken(path: String, key: String) -> Data?
    func deleteToken(path: String, key: String)
}

nonisolated final class KeychainHelper: KeychainHelperProtocol, @unchecked Sendable {
    private static let logger = Logger(subsystem: "ddorsat.Aura", category: "Keychain")

    private var memoryToken: Data?
    private let lock = NSLock()

    func saveToken(_ data: Data, path: String, key: String) {
        lock.lock()
        memoryToken = data
        lock.unlock()

        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrService: path,
                     kSecAttrAccount: key] as [CFString: Any]

        let attributes = [kSecValueData: data,
                          kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as [CFString: Any]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
        }

        if status != errSecSuccess {
            Self.logger.error("Failed to save token to Keychain, status: \(status)")
        }
    }

    func getToken(path: String, key: String) -> Data? {
        lock.lock()
        if let memoryToken {
            lock.unlock()
            return memoryToken
        }
        lock.unlock()

        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword,
                     kSecReturnData: true] as CFDictionary
        var result: AnyObject?

        SecItemCopyMatching(query, &result)

        guard let data = result as? Data else { return nil }

        lock.lock()
        memoryToken = data
        lock.unlock()

        return data
    }

    func deleteToken(path: String, key: String) {
        lock.lock()
        memoryToken = nil
        lock.unlock()

        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword] as CFDictionary
        
        SecItemDelete(query)
    }
}
