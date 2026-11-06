//
//  LocalStorage.swift
//  Aura
//
//  Created by wamhrm on 21.10.2026.
//

import Foundation

struct StorageKey<Value: Codable> {
    let name: String
}

struct StoredPersonality: Codable {
    let historyId: UUID
    let result: PersonalityResultModel
}

enum StorageKeys {
    static let personality = StorageKey<StoredPersonality>(name: "personality")
    static let history = StorageKey<[HistoryCellModel]>(name: "history")
    static let dailyInsight = StorageKey<DailyContentModel>(name: "dailyInsight")
    static let dailyTip = StorageKey<DailyContentModel>(name: "dailyTip")
}

protocol LocalStorageProtocol {
    func loadUser() -> UserModel?
    func saveUser(_ user: UserModel)
    func deleteUser()

    func load<Value>(_ key: StorageKey<Value>, userId: UUID) -> Value?
    func save<Value>(_ value: Value, key: StorageKey<Value>, userId: UUID)
    func delete<Value>(_ key: StorageKey<Value>, userId: UUID)
    func deleteAll(userId: UUID)
}

final class LocalStorage: LocalStorageProtocol {
    private let baseURL: URL
    private let fileManager: FileManager

    init(baseURL: URL = Constants.localStorageDirectory,
         fileManager: FileManager = .default) {
        self.baseURL = baseURL
        self.fileManager = fileManager
    }

    func loadUser() -> UserModel? {
        read(UserModel.self, url: userURL)
    }

    func saveUser(_ user: UserModel) {
        write(user, url: userURL)
    }

    func deleteUser() {
        try? fileManager.removeItem(at: userURL)
    }

    func load<Value>(_ key: StorageKey<Value>, userId: UUID) -> Value? {
        read(Value.self, url: fileURL(key: key, userId: userId))
    }

    func save<Value>(_ value: Value, key: StorageKey<Value>, userId: UUID) {
        write(value, url: fileURL(key: key, userId: userId))
    }

    func delete<Value>(_ key: StorageKey<Value>, userId: UUID) {
        try? fileManager.removeItem(at: fileURL(key: key, userId: userId))
    }

    func deleteAll(userId: UUID) {
        try? fileManager.removeItem(at: directory(userId: userId))
    }

    private var userURL: URL {
        baseURL.appending(path: "user.json")
    }

    private func directory(userId: UUID) -> URL {
        baseURL.appending(path: userId.uuidString, directoryHint: .isDirectory)
    }

    private func fileURL<Value>(key: StorageKey<Value>, userId: UUID) -> URL {
        directory(userId: userId).appending(path: key.name + ".json")
    }

    private func read<T: Decodable>(_ type: T.Type, url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<T: Encodable>(_ value: T, url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        excludeFromBackup()
        try? data.write(to: url, options: .atomic)
    }

    // The birth date, the answers and the results must not stay in backups out of the app's control
    private func excludeFromBackup() {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true

        var directory = baseURL
        try? directory.setResourceValues(values)
    }
}
