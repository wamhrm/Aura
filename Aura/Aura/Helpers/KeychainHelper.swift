//  KeychainHelper.swift
//  Aura
//
//  Created by ddorsat on 05.04.2026.
//

import Foundation
import Security

final class KeychainHelper {
    static let standard = KeychainHelper()

    private init() {}

    func saveToken(_ data: Data, path: String, key: String) {
        let query = [kSecValueData: data,
                     kSecClass: kSecClassGenericPassword,
                     kSecAttrService: path,
                     kSecAttrAccount: key] as CFDictionary
        SecItemDelete(query)
        SecItemAdd(query, nil)
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
