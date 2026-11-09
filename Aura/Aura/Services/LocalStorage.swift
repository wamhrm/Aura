//
//  LocalStorage.swift
//  Aura
//
//  Created by wamhrm on 21.10.2026.
//

import Foundation

final class LocalStorage {
    private let baseURL: URL
    private let fileManager = FileManager.default

    init(baseURL: URL = Constants.localStorageDirectory) {
        self.baseURL = baseURL
    }

    func loadUser() -> UserModel? {
        read(type: UserModel.self, name: "user")
    }

    func saveUser(user: UserModel) {
        write(value: user, name: "user")
    }

    func deleteUser() {
        try? fileManager.removeItem(at: fileURL(name: "user"))
    }

    func deleteAll(userId: UUID) {
        try? fileManager.removeItem(at: baseURL.appending(path: userId.uuidString, directoryHint: .isDirectory))
    }

    private func fileURL(name: String) -> URL {
        baseURL.appending(path: name + ".json")
    }

    private func read<Value: Decodable>(type: Value.Type, name: String) -> Value? {
        guard let data = try? Data(contentsOf: fileURL(name: name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<Value: Encodable>(value: Value, name: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let url = fileURL(name: name)
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        excludeFromBackup()
        try? data.write(to: url, options: .atomic)
    }

    // Profile data must not enter the device backup.
    private func excludeFromBackup() {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var directory = baseURL
        try? directory.setResourceValues(values)
    }
}
