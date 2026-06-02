//
//  PsychologyService.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

struct PsychologyService {
    private let openAIService = OpenAIService()

    func makePersonalityTest(user: User,
                             testTitles: [String],
                             req: Request) async throws -> PersonalityResultDTO {
        guard let selectedTests = PersonalityTests.from(titles: testTitles) else {
            throw Abort(.badRequest, reason: "Неизвестный тест в списке выбранных")
        }

        let uniqueSelectedTests = unique(selectedTests)

        guard uniqueSelectedTests.count >= 2 else {
            throw Abort(.badRequest, reason: "Выберите минимум 2 теста")
        }

        guard user.hasCompletedProfileInfo else {
            throw Abort(.badRequest, reason: "Заполните профиль перед прохождением теста")
        }

        return try await openAIService.makePersonalityTest(for: user,
                                                selectedTests: uniqueSelectedTests,
                                                req: req)
    }

    func makeCompatibilityTest(user: User,
                               request: CompatibilityTestRequest,
                               req: Request) async throws -> CompatibilityResultDTO {
        let partnerName = request.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let partnerGender = request.partnerGender.trimmingCharacters(in: .whitespacesAndNewlines)

        guard partnerName.count >= 2 else {
            throw Abort(.badRequest, reason: "Имя партнёра должно содержать минимум 2 символа")
        }

        guard !partnerGender.isEmpty else {
            throw Abort(.badRequest, reason: "Укажите пол партнёра")
        }

        if request.exactDateOfBirth {
            guard let dateString = request.partnerDateOfBirth,
                  UserDateFormatter.date(from: dateString) != nil else {
                throw Abort(.badRequest, reason: "Укажите дату рождения партнёра в формате ДД.ММ.ГГГГ")
            }
        }

        guard let selectedTests = CompatibilityTests.from(titles: request.selectedTests) else {
            throw Abort(.badRequest, reason: "Неизвестный тест в списке выбранных")
        }

        let uniqueSelectedTests = unique(selectedTests)

        guard uniqueSelectedTests.count >= 2 else {
            throw Abort(.badRequest, reason: "Выберите минимум 2 теста")
        }

        guard user.hasCompletedProfileInfo else {
            throw Abort(.badRequest, reason: "Заполните профиль перед прохождением теста")
        }

        let partnerRequest = CompatibilityTestRequest(partnerName: partnerName,
                                                          partnerDateOfBirth: request.partnerDateOfBirth,
                                                          partnerBirthTime: request.partnerBirthTime,
                                                          partnerAge: request.partnerAge,
                                                          partnerGender: partnerGender,
                                                          exactDateOfBirth: request.exactDateOfBirth,
                                                          selectedTests: request.selectedTests)

        return try await openAIService.makeCompatibilityTest(for: user,
                                                             partner: partnerRequest,
                                                             selectedTests: uniqueSelectedTests,
                                                             req: req)
    }

    private func unique<T: Hashable>(_ tests: [T]) -> [T] {
        var seen = Set<T>()
        return tests.filter { seen.insert($0).inserted }
    }
}
