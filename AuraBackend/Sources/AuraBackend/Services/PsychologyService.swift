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
    private let dailyTestLimit = 10
    private let dailyTestLimitWindow: TimeInterval = 24 * 60 * 60

    func makePersonalityTest(user: User, testKeys: [String], req: Request) async throws -> PersonalityResultDTO {
        guard let selectedTests = PersonalityTests.from(keys: testKeys) else {
            throw Abort(.badRequest, reason: "Неизвестный тест в списке выбранных")
        }

        let uniqueSelectedTests = unique(tests: selectedTests)

        guard uniqueSelectedTests.count >= PersonalityTests.minSelected else {
            throw Abort(.badRequest, reason: "Выберите минимум 2 теста")
        }

        guard user.hasCompletedProfileInfo else {
            throw Abort(.badRequest, reason: "Заполните профиль перед прохождением теста")
        }

        try await requireFreeTestSlot(userID: user.requireID(), database: req.db)

        return try await openAIService.makePersonalityTest(user: user,
                                                selectedTests: uniqueSelectedTests,
                                                req: req)
    }

    func makeCompatibilityTest(user: User,
                               request: CompatibilityTestRequest,
                               req: Request) async throws -> CompatibilityResultDTO {
        let partnerName = request.partnerName.trimmingCharacters(in: .whitespacesAndNewlines).capitalized

        guard partnerName.count >= InputLimits.minNameLength else {
            throw Abort(.badRequest, reason: "Имя партнёра должно содержать минимум 2 символа")
        }

        guard partnerName.count <= InputLimits.maxNameLength else {
            throw Abort(.badRequest, reason: "Имя партнёра должно быть не длиннее 50 символов")
        }

        guard let dateOfBirth = UserDateFormatter.birthDate(date: request.partnerDateOfBirth) else {
            throw Abort(.badRequest, reason: "Укажите дату рождения партнёра в формате ДД.ММ.ГГГГ")
        }

        guard UserDateFormatter.isOldEnough(birthDate: dateOfBirth) else {
            throw Abort(.badRequest, reason: "Партнёру должно быть не меньше 16 лет")
        }

        if let birthTime = request.partnerBirthTime, !UserDateFormatter.isValidTime(string: birthTime) {
            throw Abort(.badRequest, reason: "Укажите время рождения партнёра в формате ЧЧ:ММ")
        }

        guard let selectedTests = CompatibilityTests.from(keys: request.selectedTests) else {
            throw Abort(.badRequest, reason: "Неизвестный тест в списке выбранных")
        }

        let uniqueSelectedTests = unique(tests: selectedTests)

        guard uniqueSelectedTests.count >= CompatibilityTests.minSelected else {
            throw Abort(.badRequest, reason: "Выберите минимум 3 теста")
        }

        if uniqueSelectedTests.contains(.sexualCompatibility) {
            guard let userBirthDate = user.dateOfBirth,
                  UserDateFormatter.isAdult(birthDate: userBirthDate),
                  UserDateFormatter.isAdult(birthDate: dateOfBirth) else {
                throw Abort(.badRequest, reason: "Сексуальная совместимость доступна, только если вам и партнёру уже есть 18 лет")
            }
        }

        guard user.hasCompletedProfileInfo else {
            throw Abort(.badRequest, reason: "Заполните профиль перед прохождением теста")
        }

        let partnerRequest = CompatibilityTestRequest(partnerName: partnerName,
                                                      partnerDateOfBirth: request.partnerDateOfBirth,
                                                      partnerBirthTime: request.partnerBirthTime,
                                                      selectedTests: request.selectedTests)

        try await requireFreeTestSlot(userID: user.requireID(), database: req.db)

        return try await openAIService.makeCompatibilityTest(user: user,
                                                             partner: partnerRequest,
                                                             selectedTests: uniqueSelectedTests,
                                                             req: req)
    }

    func takeTestSlot(userID: UUID, database: any Database) async throws {
        try await requireFreeTestSlot(userID: userID, database: database)
        let usage = TestUsage(userID: userID)
        try await usage.save(on: database)
    }

    private func requireFreeTestSlot(userID: UUID, database: any Database) async throws {
        try await TestUsage.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt < Date().addingTimeInterval(-dailyTestLimitWindow))
            .delete()

        let testsInLastDay = try await TestUsage.query(on: database)
            .filter(\.$user.$id == userID)
            .count()

        guard testsInLastDay < dailyTestLimit else {
            throw Abort(.tooManyRequests, reason: "Достигнут лимит тестов за сутки. Попробуйте позже")
        }
    }

    private func unique<T: Hashable>(tests: [T]) -> [T] {
        var seen = Set<T>()
        return tests.filter { seen.insert($0).inserted }
    }
}
