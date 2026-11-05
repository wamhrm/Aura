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

    func fetchDailyInsight(_ user: User, _ req: Request, _ database: any Database) async throws -> DailyContentDTO {
        try await getOrGenerate(kind: .insight, user, req, database)
    }

    func fetchDailyTip(_ user: User, _ req: Request, _ database: any Database) async throws -> DailyContentDTO {
        try await getOrGenerate(kind: .tip, user, req, database)
    }

    private func getOrGenerate(kind: DailyContentKind,
                               _ user: User,
                               _ req: Request,
                               _ database: any Database) async throws -> DailyContentDTO {
        guard user.hasCompletedProfileInfo else {
            throw Abort(.badRequest, reason: "Заполните профиль перед получением контента дня")
        }

        let userID = try user.requireID()
        let today = DailyDateHelper.todayString(timeZone: req.userTimeZone)

        if let entry = try await findEntry(kind: kind, userID: userID, database),
           entry.generatedDate == today {
            return try DailyContentDTOMapper.map(entry)
        }

        return try await Self.singleFlight.run(key: "daily:\(kind.rawValue):\(userID):\(today)") {
            // Another request may have finished generating while this one was on its way here
            if let entry = try await findEntry(kind: kind, userID: userID, database),
               entry.generatedDate == today {
                return try DailyContentDTOMapper.map(entry)
            }

            let generatedText = try await generateText(kind: kind, user, req)
            let entry = try await upsertEntry(kind: kind,
                                              userID: userID,
                                              text: generatedText,
                                              generatedDate: today,
                                              database)

            return try DailyContentDTOMapper.map(entry)
        }
    }

    private func generateText(kind: DailyContentKind, _ user: User, _ req: Request) async throws -> String {
        switch kind {
            case .insight:
                return try await openAIService.makeDailyInsight(user, req)
            case .tip:
                return try await openAIService.makeDailyTip(user, req)
        }
    }

    private func upsertEntry(kind: DailyContentKind,
                             userID: User.IDValue,
                             text: String,
                             generatedDate: String,
                             _ database: any Database) async throws -> DailyContent {
        if let existing = try await findEntry(kind: kind, userID: userID, database) {
            return try await update(existing, text: text, generatedDate: generatedDate, database)
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
                  let existing = try await findEntry(kind: kind, userID: userID, database) else {
                throw error
            }
            return try await update(existing, text: text, generatedDate: generatedDate, database)
        }
    }

    private func findEntry(kind: DailyContentKind,
                           userID: User.IDValue,
                           _ database: any Database) async throws -> DailyContent? {
        try await DailyContent.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$kind == kind.rawValue)
            .first()
    }

    private func update(_ entry: DailyContent,
                        text: String,
                        generatedDate: String,
                        _ database: any Database) async throws -> DailyContent {
        entry.text = text
        entry.generatedDate = generatedDate
        try await entry.save(on: database)
        return entry
    }
}
