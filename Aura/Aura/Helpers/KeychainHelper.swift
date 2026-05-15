import Foundation
import Security

final class KeychainHelper {
    static let standard = KeychainHelper()

    private init() {}

    func save(_ data: Data, path: String, key: String) {
        let query = [kSecValueData: data,
                     kSecClass: kSecClassGenericPassword,
                     kSecAttrService: path,
                     kSecAttrAccount: key] as CFDictionary

        SecItemDelete(query)
        SecItemAdd(query, nil)
    }

    func read(path: String, key: String) -> Data? {
        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword,
                     kSecReturnData: true] as CFDictionary

        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        return result as? Data
    }

    func delete(path: String, key: String) {
        let query = [kSecAttrService: path,
                     kSecAttrAccount: key,
                     kSecClass: kSecClassGenericPassword] as CFDictionary

        SecItemDelete(query)
    }
}
