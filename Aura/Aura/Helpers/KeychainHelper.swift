//
//  KeychainHelper.swift
//  Aura
//
//  Created by wamhrm on 05.04.2026.
//

import Foundation
import os
import Security

nonisolated protocol KeychainHelperProtocol: Sendable {
    func saveToken(_ data: Data, path: String, key: String) throws
    func getToken(path: String, key: String) throws -> Data?
    func deleteToken(path: String, key: String) throws
}

nonisolated extension KeychainHelperProtocol {
    func loadAuthToken() throws -> String? {
        guard let data = try getToken(path: Constants.tokenPath, key: Constants.tokenKey) else { return nil }
        
        guard let token = String(data: data, encoding: .utf8) else {
            throw KeychainError(status: errSecDecode)
        }
        
        return token
    }

    func saveAuthToken(_ token: String) throws {
        try saveToken(Data(token.utf8), path: Constants.tokenPath, key: Constants.tokenKey)
    }

    func deleteAuthToken() throws {
        try deleteToken(path: Constants.tokenPath, key: Constants.tokenKey)
    }
}

nonisolated final class KeychainHelper: KeychainHelperProtocol {
    private static let logger = Logger(subsystem: "wamhrm.Aura", category: "Keychain")

    func saveToken(_ data: Data, path: String, key: String) throws {
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
            throw KeychainError(status: status)
        }
    }

    func getToken(path: String, key: String) throws -> Data? {
        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword,
                     kSecReturnData: true] as CFDictionary
        var result: AnyObject?

        let status = SecItemCopyMatching(query, &result)
        if status == errSecItemNotFound { return nil }
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError(status: status == errSecSuccess ? errSecDecode : status)
        }
        
        return data
    }

    func deleteToken(path: String, key: String) throws {
        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword] as CFDictionary
        
        let status = SecItemDelete(query)
        if status != errSecSuccess && status != errSecItemNotFound {
            Self.logger.error("Failed to delete token from Keychain, status: \(status)")
            throw KeychainError(status: status)
        }
    }
}

nonisolated struct KeychainError: LocalizedError {
    let status: OSStatus

    var errorDescription: String? {
        if status == errSecInteractionNotAllowed {
            return AppLanguage.text("Данные входа недоступны. Разблокируйте устройство и попробуйте ещё раз")
        }
        return AppLanguage.text("Не удалось получить доступ к данным входа. Попробуйте ещё раз")
    }
}
