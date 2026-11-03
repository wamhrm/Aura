//
//  OpenAIResultValidator.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

// A result with a missing part is refused, so the user never pays an attempt for half of a test
struct OpenAIResultValidator {
    static var unexpectedFormatError: Abort {
        Abort(.badGateway, reason: "OpenAI вернул ответ в неожиданном формате")
    }

    func requireText(_ texts: String...) throws {
        guard texts.allSatisfy(isFilled) else { throw Self.unexpectedFormatError }
    }

    // A horoscope is shared by a sign for a week, a broken one must never get saved
    func requireHoroscope(_ horoscope: HoroscopeContentResult) throws {
        let filledKeys = horoscope.items.filter { isFilled($0.description) }.map(\.key)

        guard isFilled(horoscope.description), HoroscopeDTOMapper.sphereKeys.allSatisfy(filledKeys.contains) else {
            throw Self.unexpectedFormatError
        }
    }

    func personalityBars(_ bars: [PersonalityEmotionalBar]) throws -> [PersonalityEmotionalBar] {
        let values = Dictionary(bars.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })

        return try PersonalityEmotionalBar.keys.map { key in
            guard let value = values[key] else { throw Self.unexpectedFormatError }
            return PersonalityEmotionalBar(key: key, value: clampedBarValue(value))
        }
    }

    func personalitySections(_ sections: [PersonalitySection],
                             selectedTests: [PersonalityTests]) throws -> [PersonalitySection] {
        try selectedTests.map { test in
            guard let section = sections.first(where: { $0.selectedTest == test.rawValue }) else {
                throw Self.unexpectedFormatError
            }

            let allowedKeys = PersonalityItems.allowed(for: test).map(\.rawValue)
            let items = uniqueItems(section.items.filter { allowedKeys.contains($0.key) && isFilled($0.description) },
                                    key: \.key)

            guard items.count == allowedKeys.count, isFilled(section.description) else {
                throw Self.unexpectedFormatError
            }

            return PersonalitySection(selectedTest: test.rawValue,
                                      description: section.description,
                                      items: items)
        }
    }

    func compatibilityBars(_ bars: [CompatibilityEmotionalBar]) throws -> [CompatibilityEmotionalBar] {
        let values = Dictionary(bars.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })

        return try CompatibilityEmotionalBar.keys.map { key in
            guard let value = values[key] else { throw Self.unexpectedFormatError }
            return CompatibilityEmotionalBar(key: key, value: clampedBarValue(value))
        }
    }

    func compatibilitySections(_ sections: [CompatibilitySection],
                               selectedTests: [CompatibilityTests]) throws -> [CompatibilitySection] {
        try selectedTests.map { test in
            guard let section = sections.first(where: { $0.selectedTest == test.rawValue }) else {
                throw Self.unexpectedFormatError
            }

            let allowedKeys = CompatibilityItems.allowed(for: test).map(\.rawValue)
            let items = uniqueItems(section.items.filter { allowedKeys.contains($0.key) && isFilled($0.description) },
                                    key: \.key)

            guard items.count == allowedKeys.count, isFilled(section.description) else {
                throw Self.unexpectedFormatError
            }

            return CompatibilitySection(selectedTest: test.rawValue,
                                        description: section.description,
                                        items: items)
        }
    }

    private func isFilled(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func clampedBarValue(_ value: Int) -> Int {
        min(max(value, 1), 10)
    }

    private func uniqueItems<Item>(_ items: [Item], key: (Item) -> String) -> [Item] {
        var seen = Set<String>()
        return items.filter { seen.insert(key($0)).inserted }
    }
}
