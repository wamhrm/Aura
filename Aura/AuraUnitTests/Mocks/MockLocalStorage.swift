//
//  MockLocalStorage.swift
//  AuraUnitTests
//

import Foundation
@testable import Aura

@MainActor
final class MockLocalStorage: LocalStorageProtocol {
    private(set) var user: UserModel?
    private var values: [String: Data] = [:]

    init(user: UserModel? = nil) {
        self.user = user
    }

    var storedValuesCount: Int {
        values.count
    }

    func loadUser() -> UserModel? {
        user
    }

    func saveUser(_ user: UserModel) {
        self.user = user
    }

    func deleteUser() {
        user = nil
    }

    func load<Value>(_ key: StorageKey<Value>, for userId: UUID) -> Value? {
        values[path(key.name, userId)].flatMap { try? JSONDecoder().decode(Value.self, from: $0) }
    }

    func save<Value>(_ value: Value, for key: StorageKey<Value>, userId: UUID) {
        values[path(key.name, userId)] = try? JSONEncoder().encode(value)
    }

    func delete<Value>(_ key: StorageKey<Value>, for userId: UUID) {
        values[path(key.name, userId)] = nil
    }

    func deleteAll(for userId: UUID) {
        values = values.filter { !$0.key.hasPrefix(userId.uuidString) }
    }

    private func path(_ name: String, _ userId: UUID) -> String {
        userId.uuidString + "/" + name
    }
}
