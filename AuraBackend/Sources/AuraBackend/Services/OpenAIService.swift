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

    private func replyLanguage(_ req: Request) -> ReplyLanguage {
        let value = req.headers.first(name: .acceptLanguage)?.lowercased() ?? ""
        return value.hasPrefix("en") ? .english : .russian
    }

    // MARK: - Personality
    func makePersonalityTest(user: User,
                             selectedTests: [PersonalityTests],
                             req: Request) async throws -> PersonalityResultDTO {
        let userSign = try zodiacSign(user: user)

        let language = replyLanguage(req)
        return try await client.generate(
            messages: [OpenAIMessage(role: "system", content: PersonalityPrompts.system(language: language)),
                       OpenAIMessage(role: "user", content: PersonalityPrompts.user(user: user,
                                                                                    selectedTests: selectedTests,
                                                                                    language: language))],
            responseFormat: OpenAIResponseFormat(name: "personality_result",
                                                 schema: PersonalityPrompts.schema(selectedTests: selectedTests)),
            req: req) { data in
                let analysis = try JSONDecoder().decode(PersonalityTestContent.self, from: data)

                try validator.requireText(texts: analysis.archetypeTitle,
                                          analysis.archetypeSubtitle,
                                          analysis.overview.title,
                                          analysis.overview.description)

                return PersonalityResultDTO(name: user.name.capitalized,
                                            zodiacSign: userSign.rawValue,
                                            selectedTests: selectedTests.map(\.rawValue),
                                            archetypeTitle: analysis.archetypeTitle,
                                            archetypeSubtitle: analysis.archetypeSubtitle,
                                            overview: analysis.overview,
                                            emotionalBar: try validator.personalityBars(bars: analysis.emotionalBar),
                                            sections: try validator.personalitySections(sections: analysis.sections,
                                                                                        selectedTests: selectedTests))
            }
    }

    // MARK: - Compatibility
    func makeCompatibilityTest(user: User,
                               partner: CompatibilityTestRequest,
                               selectedTests: [CompatibilityTests],
                               req: Request) async throws -> CompatibilityResultDTO {
        let userSign = try zodiacSign(user: user)
        let partnerSign = try zodiacSign(partner: partner)
        let score = CompatibilityScore.calculate(userSign: userSign, partnerSign: partnerSign)

        let language = replyLanguage(req)
        return try await client.generate(
            messages: [OpenAIMessage(role: "system", content: CompatibilityPrompts.system(language: language)),
                       OpenAIMessage(role: "user", content: CompatibilityPrompts.user(user: user,
                                                                                      partner: partner,
                                                                                      partnerSign: partnerSign,
                                                                                      score: score,
                                                                                      selectedTests: selectedTests,
                                                                                      language: language))],
            responseFormat: OpenAIResponseFormat(name: "compatibility_result",
                                                 schema: CompatibilityPrompts.schema(selectedTests: selectedTests)),
            req: req) { data in
                let analysis = try JSONDecoder().decode(CompatibilityTestContent.self, from: data)

                try validator.requireText(texts: analysis.title,
                                          analysis.subtitle,
                                          analysis.overview.title,
                                          analysis.overview.description,
                                          analysis.forecast.recognitionTitle,
                                          analysis.forecast.recognitionDescription,
                                          analysis.forecast.potentialTitle,
                                          analysis.forecast.potentialDescription)

                return CompatibilityResultDTO(userName: user.name.capitalized,
                                              userZodiacSign: userSign.rawValue,
                                              partnerName: partner.partnerName.capitalized,
                                              partnerZodiacSign: partnerSign.rawValue,
                                              compatibilityScore: score,
                                              selectedTests: selectedTests.map(\.rawValue),
                                              title: analysis.title,
                                              subtitle: analysis.subtitle,
                                              overview: analysis.overview,
                                              emotionalBar: try validator.compatibilityBars(bars: analysis.emotionalBar,
                                                                                                              score: score),
                                              sections: try validator.compatibilitySections(sections: analysis.sections,
                                                                                            selectedTests: selectedTests),
                                              forecast: analysis.forecast)
            }
    }

    // MARK: - Horoscope
    func makeHoroscope(sign: HoroscopeSign,
                       period: (start: String, end: String),
                       req: Request) async throws -> HoroscopeContentResult {
        try await client.generate(
            messages: [OpenAIMessage(role: "system", content: ContentPrompts.horoscopeSystem),
                       OpenAIMessage(role: "user", content: ContentPrompts.horoscopeUser(sign: sign, period: period))],
            responseFormat: OpenAIResponseFormat(name: "horoscope", schema: ContentPrompts.horoscopeSchema),
            req: req) { data in
                let horoscope = try JSONDecoder().decode(HoroscopeContentResult.self, from: data)

                try validator.requireHoroscope(horoscope: horoscope)

                return horoscope
            }
    }

    // MARK: - Daily Content
    func makeDailyInsight(user: User, today: String, req: Request) async throws -> String {
        try await makeDailyContent(systemPrompt: ContentPrompts.dailyInsightSystem,
                                   userPrompt: ContentPrompts.dailyInsightUser(user: user, today: today),
                                   wordRange: 8...10,
                                   req: req)
    }

    func makeDailyTip(user: User, today: String, req: Request) async throws -> String {
        try await makeDailyContent(systemPrompt: ContentPrompts.dailyTipSystem,
                                   userPrompt: ContentPrompts.dailyTipUser(user: user, today: today),
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
    private func zodiacSign(user: User) throws -> HoroscopeSign {
        guard let dateOfBirth = user.dateOfBirth,
              let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            throw Abort(.internalServerError, reason: "Не удалось определить знак зодиака")
        }

        return sign
    }

    private func zodiacSign(partner: CompatibilityTestRequest) throws -> HoroscopeSign {
        guard let dateOfBirth = UserDateFormatter.date(string: partner.partnerDateOfBirth),
              let sign = HoroscopeSign.from(dateOfBirth: dateOfBirth) else {
            throw Abort(.badRequest, reason: "Не удалось определить знак зодиака партнёра")
        }

        return sign
    }
}
