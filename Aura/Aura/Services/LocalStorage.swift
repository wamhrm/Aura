//
//  LocalStorage.swift
//  Aura
//
//  Created by wamhrm on 21.10.2026.
//

import Foundation

struct StoredPersonality: Codable {
    let historyId: UUID
    let result: PersonalityResultModel
}

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

    func loadHistory(userId: UUID) -> [HistoryCellModel]? {
        read(type: [HistoryCellModel].self, name: "history", userId: userId)
    }

    func saveHistory(history: [HistoryCellModel], userId: UUID) {
        write(value: history, name: "history", userId: userId)
    }

    func loadPersonality(userId: UUID) -> StoredPersonality? {
        read(type: StoredPersonality.self, name: "personality", userId: userId)
    }

    func savePersonality(result: StoredPersonality, userId: UUID) {
        write(value: result, name: "personality", userId: userId)
    }

    func deletePersonality(userId: UUID) {
        try? fileManager.removeItem(at: fileURL(name: "personality", userId: userId))
    }

    func loadDailyInsight(userId: UUID) -> DailyContentModel? {
        let insight = read(type: DailyContentModel.self, name: "dailyInsight", userId: userId)
        return insight?.isFromToday == true ? insight : nil
    }

    func saveDailyInsight(insight: DailyContentModel, userId: UUID) {
        write(value: insight, name: "dailyInsight", userId: userId)
    }

    func loadDailyTip(userId: UUID) -> DailyContentModel? {
        let tip = read(type: DailyContentModel.self, name: "dailyTip", userId: userId)
        return tip?.isFromToday == true ? tip : nil
    }

    func saveDailyTip(tip: DailyContentModel, userId: UUID) {
        write(value: tip, name: "dailyTip", userId: userId)
    }

    func loadHoroscope(userId: UUID) -> HoroscopeModel? {
        let url = fileURL(name: "horoscope", userId: userId)
        guard let savedAt = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else { return nil }

        // Match the server's weeks, which start on Monday.
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        guard calendar.isDate(savedAt, equalTo: Date(), toGranularity: .weekOfYear) else { return nil }
        return read(type: HoroscopeModel.self, name: "horoscope", userId: userId)
    }

    func saveHoroscope(horoscope: HoroscopeModel, userId: UUID) {
        write(value: horoscope, name: "horoscope", userId: userId)
    }

    func deleteAll(userId: UUID) {
        try? fileManager.removeItem(at: baseURL.appending(path: userId.uuidString, directoryHint: .isDirectory))
    }

    private func fileURL(name: String, userId: UUID? = nil) -> URL {
        var directory = baseURL
        if let userId {
            directory = directory.appending(path: userId.uuidString, directoryHint: .isDirectory)
        }
        return directory.appending(path: name + ".json")
    }

    private func read<Value: Decodable>(type: Value.Type, name: String, userId: UUID? = nil) -> Value? {
        guard let data = try? Data(contentsOf: fileURL(name: name, userId: userId)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<Value: Encodable>(value: Value, name: String, userId: UUID? = nil) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let url = fileURL(name: name, userId: userId)
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        excludeFromBackup()
        try? data.write(to: url, options: .atomic)
    }

    // Profile data and test results must not enter the device backup.
    private func excludeFromBackup() {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var directory = baseURL
        try? directory.setResourceValues(values)
    }
}
