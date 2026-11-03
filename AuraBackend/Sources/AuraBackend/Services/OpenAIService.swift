//
//  OpenAIService.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Foundation
import Vapor

struct OpenAIService {
    private let client = OpenAIClient()
    private let validator = OpenAIResultValidator()

    // MARK: - Personality
    func makePersonalityTest(for user: User,
                             selectedTests: [PersonalityTests],
                             req: Request) async throws -> PersonalityResultDTO {
        let userSign = try zodiacSign(of: user)

        return try await client.generate(
            messages: [OpenAIMessage(role: "system", content: PersonalityPrompts.system),
                       OpenAIMessage(role: "user", content: PersonalityPrompts.user(for: user,
                                                                                    selectedTests: selectedTests))],
            responseFormat: OpenAIResponseFormat(name: "personality_result",
                                                 schema: PersonalityPrompts.schema(for: selectedTests)),
            req: req) { data in
                let analysis = try JSONDecoder().decode(PersonalityTestContent.self, from: data)

                try validator.requireText(analysis.archetypeTitle,
                                          analysis.archetypeSubtitle,
                                          analysis.overview.title,
                                          analysis.overview.description)

                return PersonalityResultDTO(name: user.name,
                                            zodiacSign: userSign.rawValue,
                                            selectedTests: selectedTests.map(\.rawValue),
                                            archetypeTitle: analysis.archetypeTitle,
                                            archetypeSubtitle: analysis.archetypeSubtitle,
                                            overview: analysis.overview,
                                            emotionalBar: try validator.personalityBars(analysis.emotionalBar),
                                            sections: try validator.personalitySections(analysis.sections,
                                                                                        selectedTests: selectedTests))
            }
    }

    // MARK: - Compatibility
    func makeCompatibilityTest(for user: User,
                               partner: CompatibilityTestRequest,
                               selectedTests: [CompatibilityTests],
                               req: Request) async throws -> CompatibilityResultDTO {
        let userSign = try zodiacSign(of: user)
        let score = CompatibilityScore.calculate(user: user, partner: partner)

        return try await client.generate(
            messages: [OpenAIMessage(role: "system", content: CompatibilityPrompts.system),
                       OpenAIMessage(role: "user", content: CompatibilityPrompts.user(for: user,
                                                                                      partner: partner,
                                                                                      score: score,
                                                                                      selectedTests: selectedTests))],
            responseFormat: OpenAIResponseFormat(name: "compatibility_result",
                                                 schema: CompatibilityPrompts.schema(for: selectedTests)),
            req: req) { data in
                let analysis = try JSONDecoder().decode(CompatibilityTestContent.self, from: data)
                let partnerDate = UserDateFormatter.date(from: partner.partnerDateOfBirth)

                try validator.requireText(analysis.title,
                                          analysis.subtitle,
                                          analysis.overview.title,
                                          analysis.overview.description,
                                          analysis.forecast.recognitionTitle,
                                          analysis.forecast.recognitionDescription,
                                          analysis.forecast.potentialTitle,
                                          analysis.forecast.potentialDescription)

                return CompatibilityResultDTO(userName: user.name,
                                              userZodiacSign: userSign.rawValue,
                                              partnerName: partner.partnerName,
                                              partnerZodiacSign: partnerDate.flatMap(HoroscopeSign.from(dateOfBirth:))?.rawValue,
                                              compatibilityScore: score,
                                              selectedTests: selectedTests.map(\.rawValue),
                                              title: analysis.title,
                                              subtitle: analysis.subtitle,
                                              overview: analysis.overview,
                                              emotionalBar: try validator.compatibilityBars(analysis.emotionalBar),
                                              sections: try validator.compatibilitySections(analysis.sections,
                                                                                            selectedTests: selectedTests),
                                              forecast: analysis.forecast)
            }
    }

    // MARK: - Horoscope
    func makeHoroscope(for sign: HoroscopeSign,
                       period: (start: String, end: String),
                       req: Request) async throws -> HoroscopeContentResult {
        try await client.generate(
            messages: [OpenAIMessage(role: "system", content: ContentPrompts.horoscopeSystem),
                       OpenAIMessage(role: "user", content: ContentPrompts.horoscopeUser(for: sign, period: period))],
            responseFormat: OpenAIResponseFormat(name: "horoscope", schema: ContentPrompts.horoscopeSchema),
            req: req) { data in
                let horoscope = try JSONDecoder().decode(HoroscopeContentResult.self, from: data)

                try validator.requireHoroscope(horoscope)

                return horoscope
            }
    }

    // MARK: - Daily Content
    func makeDailyInsight(for user: User, req: Request) async throws -> String {
        try await makeDailyContent(systemPrompt: ContentPrompts.dailyInsightSystem,
                                   userPrompt: ContentPrompts.dailyInsightUser(for: user, today: DailyDateHelper.todayString(in: req.userTimeZone)),
                                   wordRange: 8...10,
                                   req: req)
    }

    func makeDailyTip(for user: User, req: Request) async throws -> String {
        try await makeDailyContent(systemPrompt: ContentPrompts.dailyTipSystem,
                                   userPrompt: ContentPrompts.dailyTipUser(for: user, today: DailyDateHelper.todayString(in: req.userTimeZone)),
                                   wordRange: 15...20,
                                   req: req)
    }

    private func makeDailyContent(systemPrompt: String,
                                  userPrompt: String,
                                  wordRange: ClosedRange<Int>,
                                  req: Request) async throws -> String {
        try await client.generate(
            messages: [OpenAIMessage(role: "system", content: systemPrompt),
                       OpenAIMessage(role: "user", content: userPrompt)],
            responseFormat: OpenAIResponseFormat(name: "daily_content", schema: ContentPrompts.dailySchema),
            req: req) { data in
                let result = try JSONDecoder().decode(DailyContentResult.self, from: data)
                let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !text.isEmpty else {
                    throw Abort(.badGateway, reason: "OpenAI вернул пустой текст")
                }

                let wordCount = text.split(whereSeparator: \.isWhitespace).count

                if !wordRange.contains(wordCount) {
                    req.logger.info("OpenAI daily content has \(wordCount) words, expected \(wordRange)")
                }

                guard wordCount <= wordRange.upperBound * 2 else {
                    throw Abort(.badGateway, reason: "OpenAI вернул текст с неверным количеством слов")
                }

                return text
            }
    }

    // MARK: - Helpers
    private func zodiacSign(of user: User) throws -> HoroscopeSign {
        guard let sign = user.dateOfBirth.flatMap(HoroscopeSign.from(dateOfBirth:)) else {
            throw Abort(.internalServerError, reason: "Не удалось определить знак зодиака")
        }

        return sign
    }
}
