//
//  PsychologyService.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

struct PsychologyService {
    private let openAIService = OpenAIService()

    func makePersonalityTest(user: User,
                             testKeys: [String],
                             req: Request) async throws -> PersonalityResultDTO {
        guard let selectedTests = PersonalityTests.from(keys: testKeys) else {
            throw Abort(.badRequest, reason: "Неизвестный тест в списке выбранных")
        }

        let uniqueSelectedTests = unique(selectedTests)

        guard uniqueSelectedTests.count >= PersonalityTests.minSelected else {
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

        guard partnerName.count >= InputLimits.minNameLength else {
            throw Abort(.badRequest, reason: "Имя партнёра должно содержать минимум 2 символа")
        }

        guard partnerName.count <= InputLimits.maxNameLength else {
            throw Abort(.badRequest, reason: "Имя партнёра должно быть не длиннее 50 символов")
        }

        guard ProfileInfoOptions.genders.contains(partnerGender) else {
            throw Abort(.badRequest, reason: "Укажите пол партнёра")
        }

        guard let dateOfBirth = UserDateFormatter.birthDate(from: request.partnerDateOfBirth) else {
            throw Abort(.badRequest, reason: "Укажите дату рождения партнёра в формате ДД.ММ.ГГГГ")
        }

        guard UserDateFormatter.isOldEnough(dateOfBirth) else {
            throw Abort(.badRequest, reason: "Партнёру должно быть не меньше 16 лет")
        }

        if let birthTime = request.partnerBirthTime, !UserDateFormatter.isValidTime(birthTime) {
            throw Abort(.badRequest, reason: "Укажите время рождения партнёра в формате ЧЧ:ММ")
        }

        guard ProfileInfoOptions.socialTypes.contains(request.partnerSocialType),
              ProfileInfoOptions.conflictStyles.contains(request.partnerConflictStyle),
              ProfileInfoOptions.emotionalCores.contains(request.partnerEmotionalCore),
              ProfileInfoOptions.decisionStyles.contains(request.partnerDecisionStyle),
              ProfileInfoOptions.coreFocuses.contains(request.partnerCoreFocus) else {
            throw Abort(.badRequest, reason: "Ответьте на все вопросы о партнёре")
        }

        guard let selectedTests = CompatibilityTests.from(keys: request.selectedTests) else {
            throw Abort(.badRequest, reason: "Неизвестный тест в списке выбранных")
        }

        let uniqueSelectedTests = unique(selectedTests)

        guard uniqueSelectedTests.count >= CompatibilityTests.minSelected else {
            throw Abort(.badRequest, reason: "Выберите минимум 3 теста")
        }

        guard user.hasCompletedProfileInfo else {
            throw Abort(.badRequest, reason: "Заполните профиль перед прохождением теста")
        }

        let partnerRequest = CompatibilityTestRequest(partnerName: partnerName,
                                                      partnerDateOfBirth: request.partnerDateOfBirth,
                                                      partnerBirthTime: request.partnerBirthTime,
                                                      partnerGender: partnerGender,
                                                      partnerSocialType: request.partnerSocialType,
                                                      partnerConflictStyle: request.partnerConflictStyle,
                                                      partnerEmotionalCore: request.partnerEmotionalCore,
                                                      partnerDecisionStyle: request.partnerDecisionStyle,
                                                      partnerCoreFocus: request.partnerCoreFocus,
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
