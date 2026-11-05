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

        if let entry = try await findEntry(kind: kind, userID: userID, database: database),
           entry.generatedDate == today {
            return try DailyContentDTOMapper.map(entry: entry)
        }

        return try await Self.singleFlight.run(key: "daily:\(kind.rawValue):\(userID):\(today)") {
            // Another request may have finished generating while this one was on its way here
            if let entry = try await findEntry(kind: kind, userID: userID, database: database),
               entry.generatedDate == today {
                return try DailyContentDTOMapper.map(entry: entry)
            }

            let generatedText = try await generateText(kind: kind, user: user, req: req)
            let entry = try await upsertEntry(kind: kind,
                                              userID: userID,
                                              text: generatedText,
                                              generatedDate: today,
                                              database: database)

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

    private func upsertEntry(kind: DailyContentKind,
                             userID: User.IDValue,
                             text: String,
                             generatedDate: String,
                             database: any Database) async throws -> DailyContent {
        if let existing = try await findEntry(kind: kind, userID: userID, database: database) {
            return try await update(entry: existing, text: text, generatedDate: generatedDate, database: database)
        }

        let entry = DailyContent(userID: userID,
                                 kind: kind,
                                 text: text,
                                 generatedDate: generatedDate)

        do {
            try await entry.save(on: database)
            return entry
        } catch {
            guard (error as? any DatabaseError)?.isConstraintFailure == true,
                  let existing = try await findEntry(kind: kind, userID: userID, database: database) else {
                throw error
            }
            return try await update(entry: existing, text: text, generatedDate: generatedDate, database: database)
        }
    }

    private func findEntry(kind: DailyContentKind,
                           userID: User.IDValue,
                           database: any Database) async throws -> DailyContent? {
        try await DailyContent.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$kind == kind.rawValue)
            .first()
    }

    private func update(entry: DailyContent,
                        text: String,
                        generatedDate: String,
                        database: any Database) async throws -> DailyContent {
        entry.text = text
        entry.generatedDate = generatedDate
        try await entry.save(on: database)
        return entry
    }
}
