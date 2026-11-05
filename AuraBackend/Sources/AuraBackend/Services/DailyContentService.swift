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

    private enum Reservation {
        case cached(DailyContentDTO)
        case started(DailyGenerationAttempt)
    }

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
            let reservation = try await reserveGeneration(kind: kind, userID: userID, date: today, database: database)

            switch reservation {
                case .cached(let result):
                    return result
                case .started(let attempt):
                    do {
                        let text = try await generateText(kind: kind, user: user, req: req)
                        return try await database.transaction { transaction in
                            try await transaction.sql().raw("SELECT id FROM users WHERE id = \(bind: userID) FOR UPDATE").run()
                            let entry = DailyContent(userID: userID, kind: kind, text: text, generatedDate: today)
                            try await entry.save(on: transaction)
                            attempt.finishedAt = Date()
                            try await attempt.update(on: transaction)
                            return try DailyContentDTOMapper.map(entry: entry)
                        }
                    } catch {
                        // Failed attempts still count toward the limit.
                        do {
                            attempt.finishedAt = Date()
                            try await attempt.update(on: database)
                        } catch {
                            req.logger.error("Could not finish daily generation attempt: \(error)")
                        }
                        throw error
                    }
            }
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

    private func reserveGeneration(kind: DailyContentKind,
                                   userID: User.IDValue,
                                   date: String,
                                   database: any Database) async throws -> Reservation {
        try await database.transaction { transaction in
            try await transaction.sql().raw("SELECT id FROM users WHERE id = \(bind: userID) FOR UPDATE").run()

            if let entry = try await findEntry(kind: kind, userID: userID, date: date, database: transaction) {
                return .cached(try DailyContentDTOMapper.map(entry: entry))
            }

            let runningAttempt = try await DailyGenerationAttempt.query(on: transaction)
                .filter(\.$user.$id == userID)
                .filter(\.$kind == kind.rawValue)
                .filter(\.$generatedDate == date)
                .filter(\.$finishedAt == nil)
                .first()

            guard runningAttempt == nil else {
                throw Abort(.conflict, reason: "Результат генерации для этой даты ещё не подтверждён. Проверьте его позже")
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
            return .started(attempt)
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
