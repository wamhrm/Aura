//
//  LocalStorage.swift
//  Aura
//
//  Created by ddorsat on 21.10.2026.
//

import Foundation

struct StorageKey<Value: Codable> {
    let name: String
}

enum StorageKeys {
    static let horoscope = StorageKey<HoroscopeModel>(name: "horoscope")
    static let personality = StorageKey<PersonalityResultModel>(name: "personality")
    static let history = StorageKey<[HistoryCellModel]>(name: "history")
    static let dailyInsight = StorageKey<DailyContentModel>(name: "dailyInsight")
    static let dailyTip = StorageKey<DailyContentModel>(name: "dailyTip")
}

protocol LocalStorageProtocol {
    func loadUser() -> UserModel?
    func saveUser(_ user: UserModel)
    func deleteUser()

    func load<Value>(_ key: StorageKey<Value>, for userId: UUID) -> Value?
    func save<Value>(_ value: Value, for key: StorageKey<Value>, userId: UUID)
    func delete<Value>(_ key: StorageKey<Value>, for userId: UUID)
    func deleteAll(for userId: UUID)
}

final class LocalStorage: LocalStorageProtocol {
    private let baseURL: URL
    private let fileManager: FileManager

    init(baseURL: URL = .applicationSupportDirectory.appending(path: "LocalStorage", directoryHint: .isDirectory),
         fileManager: FileManager = .default) {
        self.baseURL = baseURL
        self.fileManager = fileManager
    }

    func loadUser() -> UserModel? {
        read(UserModel.self, at: userURL)
    }

    func saveUser(_ user: UserModel) {
        write(user, to: userURL)
    }

    func deleteUser() {
        try? fileManager.removeItem(at: userURL)
    }

    func load<Value>(_ key: StorageKey<Value>, for userId: UUID) -> Value? {
        read(Value.self, at: fileURL(for: key, userId: userId))
    }

    func save<Value>(_ value: Value, for key: StorageKey<Value>, userId: UUID) {
        write(value, to: fileURL(for: key, userId: userId))
    }

    func delete<Value>(_ key: StorageKey<Value>, for userId: UUID) {
        try? fileManager.removeItem(at: fileURL(for: key, userId: userId))
    }

    func deleteAll(for userId: UUID) {
        try? fileManager.removeItem(at: directory(for: userId))
    }

    func migrateLegacyUserDefaults(_ defaults: UserDefaults = .standard) {
        if loadUser() == nil,
           let data = defaults.data(forKey: Constants.userKey),
           let user = try? JSONDecoder().decode(UserModel.self, from: data) {
            saveUser(user)
        }

        let legacyPrefixes = [Constants.horoscopeKeyPrefix,
                              Constants.personalityKeyPrefix,
                              Constants.historyKeyPrefix,
                              Constants.dailyInsightKeyPrefix,
                              Constants.dailyTipKeyPrefix]

        for key in defaults.dictionaryRepresentation().keys
        where key == Constants.userKey || legacyPrefixes.contains(where: key.hasPrefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private var userURL: URL {
        baseURL.appending(path: "user.json")
    }

    private func directory(for userId: UUID) -> URL {
        baseURL.appending(path: userId.uuidString, directoryHint: .isDirectory)
    }

    private func fileURL<Value>(for key: StorageKey<Value>, userId: UUID) -> URL {
        directory(for: userId).appending(path: key.name + ".json")
    }

    private func read<T: Decodable>(_ type: T.Type, at url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
