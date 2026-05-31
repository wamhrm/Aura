//  KeychainHelper.swift
//  Aura
//
//  Created by ddorsat on 05.04.2026.
//

import Foundation
import Security

nonisolated protocol KeychainHelperProtocol: Sendable {
    func saveToken(_ data: Data, path: String, key: String)
    func getToken(path: String, key: String) -> Data?
    func deleteToken(path: String, key: String)
}

nonisolated final class KeychainHelper: KeychainHelperProtocol, @unchecked Sendable {
    private var memoryToken: Data?
    private let lock = NSLock()

    func saveToken(_ data: Data, path: String, key: String) {
        lock.lock()
        memoryToken = data
        lock.unlock()

        let query = [kSecValueData: data,
                     kSecClass: kSecClassGenericPassword,
                     kSecAttrService: path,
                     kSecAttrAccount: key] as CFDictionary
        
        SecItemDelete(query)
        SecItemAdd(query, nil)
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
