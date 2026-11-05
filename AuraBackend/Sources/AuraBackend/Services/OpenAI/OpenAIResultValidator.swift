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

    func requireText(texts: String...) throws {
        guard texts.allSatisfy(isFilled) else { throw Self.unexpectedFormatError }
    }

    // A horoscope is shared by a sign for a week, a broken one must never get saved
    func requireHoroscope(horoscope: HoroscopeContentResult) throws {
        let filledKeys = horoscope.items.filter { isFilled(text: $0.description) }.map(\.key)

        guard isFilled(text: horoscope.description), HoroscopeDTOMapper.sphereKeys.allSatisfy(filledKeys.contains) else {
            throw Self.unexpectedFormatError
        }
    }

    func personalityBars(bars: [PersonalityEmotionalBar]) throws -> [PersonalityEmotionalBar] {
        let values = Dictionary(bars.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })

        return try PersonalityEmotionalBar.keys.map { key in
            guard let value = values[key] else { throw Self.unexpectedFormatError }
            return PersonalityEmotionalBar(key: key, value: clampedBarValue(value: value))
        }
    }

    func personalitySections(sections: [PersonalitySection],
                             selectedTests: [PersonalityTests]) throws -> [PersonalitySection] {
        try selectedTests.map { test in
            guard let section = sections.first(where: { $0.selectedTest == test.rawValue }) else {
                throw Self.unexpectedFormatError
            }

            let allowedKeys = PersonalityItems.allowed(test: test).map(\.rawValue)
            let items = uniqueItems(items: section.items.filter { allowedKeys.contains($0.key) && isFilled(text: $0.description) },
                                    key: \.key)

            guard items.count == allowedKeys.count, isFilled(text: section.description) else {
                throw Self.unexpectedFormatError
            }

            return PersonalitySection(selectedTest: test.rawValue,
                                      description: section.description,
                                      items: items)
        }
    }

    func compatibilityBars(bars: [CompatibilityEmotionalBar]) throws -> [CompatibilityEmotionalBar] {
        let values = Dictionary(bars.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })

        return try CompatibilityEmotionalBar.keys.map { key in
            guard let value = values[key] else { throw Self.unexpectedFormatError }
            return CompatibilityEmotionalBar(key: key, value: clampedBarValue(value: value))
        }
    }

    func compatibilitySections(sections: [CompatibilitySection],
                               selectedTests: [CompatibilityTests]) throws -> [CompatibilitySection] {
        try selectedTests.map { test in
            guard let section = sections.first(where: { $0.selectedTest == test.rawValue }) else {
                throw Self.unexpectedFormatError
            }

            let allowedKeys = CompatibilityItems.allowed(test: test).map(\.rawValue)
            let items = uniqueItems(items: section.items.filter { allowedKeys.contains($0.key) && isFilled(text: $0.description) },
                                    key: \.key)

            guard items.count == allowedKeys.count, isFilled(text: section.description) else {
                throw Self.unexpectedFormatError
            }

            return CompatibilitySection(selectedTest: test.rawValue,
                                        description: section.description,
                                        items: items)
        }
    }

    private func isFilled(text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func clampedBarValue(value: Int) -> Int {
        min(max(value, 1), 10)
    }

    private func uniqueItems<Item>(items: [Item], key: (Item) -> String) -> [Item] {
        var seen = Set<String>()
        return items.filter { seen.insert(key($0)).inserted }
    }
}
