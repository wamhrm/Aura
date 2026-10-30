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

nonisolated extension KeychainHelperProtocol {
    func loadAuthToken() -> String? {
        guard let data = getToken(path: Constants.tokenPath, key: Constants.tokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveAuthToken(_ token: String) {
        saveToken(Data(token.utf8), path: Constants.tokenPath, key: Constants.tokenKey)
    }

    func deleteAuthToken() {
        deleteToken(path: Constants.tokenPath, key: Constants.tokenKey)
    }
}

nonisolated final class KeychainHelper: KeychainHelperProtocol {
    private static let logger = Logger(subsystem: "ddorsat.Aura", category: "Keychain")

    func saveToken(_ data: Data, path: String, key: String) {
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
        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword,
                     kSecReturnData: true] as CFDictionary
        var result: AnyObject?

        SecItemCopyMatching(query, &result)

        return result as? Data
    }

    func deleteToken(path: String, key: String) {
        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword] as CFDictionary
        
        SecItemDelete(query)
    }
}
