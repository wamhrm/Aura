//
//  UserDefaultsHelper.swift
//  Aura
//
//  Created by ddorsat on 22.05.2026.
//

import Foundation

struct UserDefaultsHelper {
    static func saveHoroscopeLocally(_ horoscope: HoroscopeModel, for userId: UUID) {
        let key = horoscopeStorageKey(for: userId)
        UserDefaults.standard.removeObject(forKey: key)

        guard let data = try? JSONEncoder().encode(horoscope) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func getLocalHoroscope(for userId: UUID) -> HoroscopeModel? {
        guard let data = UserDefaults.standard.data(forKey: horoscopeStorageKey(for: userId)) else {
            return nil
        }

        return try? JSONDecoder().decode(HoroscopeModel.self, from: data)
    }

    static func deleteLocalHoroscope(for userId: UUID) {
        UserDefaults.standard.removeObject(forKey: horoscopeStorageKey(for: userId))
    }

    static func savePersonalityLocally(_ result: PersonalityResultModel, for userId: UUID) {
        let key = personalityStorageKey(for: userId)
        UserDefaults.standard.removeObject(forKey: key)

        guard let data = try? JSONEncoder().encode(result) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func getLocalPersonality(for userId: UUID) -> PersonalityResultModel? {
        guard let data = UserDefaults.standard.data(forKey: personalityStorageKey(for: userId)) else {
            return nil
        }

        return try? JSONDecoder().decode(PersonalityResultModel.self, from: data)
    }

    static func deleteLocalPersonality(for userId: UUID) {
        UserDefaults.standard.removeObject(forKey: personalityStorageKey(for: userId))
    }

    static func saveHistoryLocally(_ history: [HistoryCellModel], for userId: UUID) {
        let key = historyStorageKey(for: userId)
        UserDefaults.standard.removeObject(forKey: key)

        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func getLocalHistory(for userId: UUID) -> [HistoryCellModel]? {
        guard let data = UserDefaults.standard.data(forKey: historyStorageKey(for: userId)) else {
            return nil
        }

        return try? JSONDecoder().decode([HistoryCellModel].self, from: data)
    }

    static func deleteLocalHistory(for userId: UUID) {
        UserDefaults.standard.removeObject(forKey: historyStorageKey(for: userId))
    }
    
    static func saveDailyInsightLocally(_ insight: DailyContentModel, for userId: UUID) {
        let key = dailyInsightStorageKey(for: userId)
        UserDefaults.standard.removeObject(forKey: key)

        guard let data = try? JSONEncoder().encode(insight) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func getLocalDailyInsight(for userId: UUID) -> DailyContentModel? {
        guard let data = UserDefaults.standard.data(forKey: dailyInsightStorageKey(for: userId)) else {
            return nil
        }

        return try? JSONDecoder().decode(DailyContentModel.self, from: data)
    }

    static func deleteLocalDailyInsight(for userId: UUID) {
        UserDefaults.standard.removeObject(forKey: dailyInsightStorageKey(for: userId))
    }

    static func saveDailyTipLocally(_ tip: DailyContentModel, for userId: UUID) {
        let key = dailyTipStorageKey(for: userId)
        UserDefaults.standard.removeObject(forKey: key)

        guard let data = try? JSONEncoder().encode(tip) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func getLocalDailyTip(for userId: UUID) -> DailyContentModel? {
        guard let data = UserDefaults.standard.data(forKey: dailyTipStorageKey(for: userId)) else {
            return nil
        }

        return try? JSONDecoder().decode(DailyContentModel.self, from: data)
    }

    static func deleteLocalDailyTip(for userId: UUID) {
        UserDefaults.standard.removeObject(forKey: dailyTipStorageKey(for: userId))
    }

    private static func horoscopeStorageKey(for userId: UUID) -> String {
        return Constants.horoscopeKeyPrefix + userId.uuidString
    }

    private static func personalityStorageKey(for userId: UUID) -> String {
        return Constants.personalityKeyPrefix + userId.uuidString
    }

    private static func dailyInsightStorageKey(for userId: UUID) -> String {
        return Constants.dailyInsightKeyPrefix + userId.uuidString
    }

    private static func dailyTipStorageKey(for userId: UUID) -> String {
        return Constants.dailyTipKeyPrefix + userId.uuidString
    }

    private static func historyStorageKey(for userId: UUID) -> String {
        return Constants.historyKeyPrefix + userId.uuidString
    }
}
