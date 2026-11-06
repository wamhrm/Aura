//
//  DailyContentService.swift
//  AuraBackend
//
//  Created by wamhrm on 26.05.2026.
//

import Fluent
import Vapor

struct DailyContentService {
    private static let singleFlight = SingleFlight<DailyContentDTO>()
    private let openAIService = OpenAIService()
    private let generationLimit = 2
    private let generationWindow: TimeInterval = 24 * 60 * 60

    func fetchDailyInsight(user: User, req: Request, database: any Database) async throws -> DailyContentDTO {
        try await getOrGenerate(kind: .insight, user: user, req: req, database: database)
    }

    func fetchDailyTip(user: User, req: Request, database: any Database) async throws -> DailyContentDTO {
        try await getOrGenerate(kind: .tip, user: user, req: req, database: database)
    }

    private func getOrGenerate(kind: DailyContentKind,
                               user: User,
                               req: Request,
                               database: any Database) async throws -> DailyContentDTO {
        guard user.hasCompletedProfileInfo else {
            throw Abort(.badRequest, reason: "Заполните профиль перед получением контента дня")
        }

        let userID = try user.requireID()
        let today = DailyDateHelper.todayString(timeZone: req.userTimeZone)

        if let entry = try await findEntry(kind: kind, userID: userID, date: today, database: database) {
            return try DailyContentDTOMapper.map(entry: entry)
        }

        return try await Self.singleFlight.run(key: "daily:\(kind.rawValue):\(userID):\(today)") {
            if let cached = try await reserveGeneration(kind: kind, userID: userID, date: today, database: database) {
                return cached
            }

            let text = try await generateText(kind: kind, user: user, req: req)
            let entry = DailyContent(userID: userID, kind: kind, text: text, generatedDate: today)

            do {
                try await entry.save(on: database)
            } catch {
                guard (error as? any DatabaseError)?.isConstraintFailure == true,
                      let existing = try await findEntry(kind: kind, userID: userID, date: today, database: database) else {
                    throw error
                }
                return try DailyContentDTOMapper.map(entry: existing)
            }

            return try DailyContentDTOMapper.map(entry: entry)
        }
    }

    private func generateText(kind: DailyContentKind, user: User, req: Request) async throws -> String {
        switch kind {
            case .insight:
                return try await openAIService.makeDailyInsight(user: user, req: req)
            case .tip:
                return try await openAIService.makeDailyTip(user: user, req: req)
        }
    }

    // Return cached content if it appeared while waiting; otherwise reserve an attempt, including failures.
    private func reserveGeneration(kind: DailyContentKind,
                                   userID: User.IDValue,
                                   date: String,
                                   database: any Database) async throws -> DailyContentDTO? {
        try await database.transaction { transaction in
            try await transaction.sql().raw("SELECT id FROM users WHERE id = \(bind: userID) FOR UPDATE").run()

            if let entry = try await findEntry(kind: kind, userID: userID, date: date, database: transaction) {
                return try DailyContentDTOMapper.map(entry: entry)
            }

            let recentAttempts = try await DailyGenerationAttempt.query(on: transaction)
                .filter(\.$user.$id == userID)
                .filter(\.$kind == kind.rawValue)
                .filter(\.$createdAt > Date().addingTimeInterval(-generationWindow))
                .count()

            guard recentAttempts < generationLimit else {
                throw Abort(.tooManyRequests, reason: "Достигнут лимит генерации этого контента за 24 часа. Попробуйте позже")
            }

            let attempt = DailyGenerationAttempt(userID: userID, kind: kind, generatedDate: date)
            try await attempt.save(on: transaction)
            return nil
        }
    }

    private func findEntry(kind: DailyContentKind,
                           userID: User.IDValue,
                           date: String,
                           database: any Database) async throws -> DailyContent? {
        try await DailyContent.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$kind == kind.rawValue)
            .filter(\.$generatedDate == date)
            .first()
    }
}
