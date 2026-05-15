//
//  PersonalityService.swift
//  Aura
//
//  Created by ddorsat on 12.04.2026.
//


import Foundation
import Combine

protocol PersonalityServiceProtocol: AnyObject {
    func generate(selectedTests: [TestTypes]) async throws -> PersonalityResult
}

final class PersonalityService: ObservableObject, PersonalityServiceProtocol {
    func generate(selectedTests: [TestTypes]) async throws -> PersonalityResult {
        try await NetworkHelper.generatePersonality(selectedTests: selectedTests)
    }
}

struct PersonalityResult: Decodable {
    let name: String
    let zodiacSign: String
    let selectedTests: [TestTypes]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityTextSection
    let scales: [PersonalityScale]
    let sections: [PersonalityResultSection]
}

struct PersonalityTextSection: Decodable {
    let title: String
    let description: String
}

struct PersonalityScale: Decodable {
    let title: String
    let value: Int
}

struct PersonalityResultSection: Hashable, Decodable {
    let selectedTest: String
    let title: String
    let description: String
    let items: [PersonalityResultItem]
}

struct PersonalityResultItem: Hashable, Decodable {
    let title: String
    let description: String
}

extension PersonalityResult {
    static let mock = PersonalityResult(
        name: "Дмитрий",
        zodiacSign: "♒",
        selectedTests: [.astrology, .attachmentStyle],
        archetypeTitle: "Интуитивный креатор",
        archetypeSubtitle: "Вы стремитесь к глубине и аутентичности в своих связях",
        overview: PersonalityTextSection(
            title: "Основная характеристика",
            description: "Ты — интроверт с сильной интуицией, который в отношениях ищет глубину, но быстро выгорает от поверхностного трепа. Астрология и нумерология показывают, что у тебя сейчас период трансформации"
        ),
        scales: [
            PersonalityScale(title: "Эмоциональность", value: 7),
            PersonalityScale(title: "Рациональность", value: 8),
            PersonalityScale(title: "Открытость", value: 6)
        ],
        sections: [
            PersonalityResultSection(
                selectedTest: TestTypes.astrology.rawValue,
                title: "Основная характеристика",
                description: "Ты — интроверт с сильной интуицией, который в отношениях ищет глубину, но быстро выгорает от поверхностного трепа. Астрология и нумерология показывают, что у тебя сейчас период трансформации",
                items: [PersonalityResultItem(
                    title: "Манеры",
                    description: "Вам важно чувствовать эмоциональную вовлечённость партнёра."
                ),
                PersonalityResultItem(
                    title: "Четкость",
                    description: "Вы комфортно чувствуете себя, когда есть время на себя."
                )]
            ),
            PersonalityResultSection(
                selectedTest: TestTypes.attachmentStyle.rawValue,
                title: "Поведенческие паттерны",
                description: "Вы стремитесь к надёжной связи, но сохраняете личное пространство.",
                items: [
                    PersonalityResultItem(
                        title: "Близость",
                        description: "Вам важно чувствовать эмоциональную вовлечённость партнёра."
                    ),
                    PersonalityResultItem(
                        title: "Границы",
                        description: "Вы комфортно чувствуете себя, когда есть время на себя."
                    )
                ]
            )
        ]
    )
}
