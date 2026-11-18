//
//  DailyContentService.swift
//  AuraBackend
//
//  Created by wamhrm on 26.05.2026.
//

import Fluent
import Vapor

struct DailyContentService {
    private let openAIService = OpenAIService()
    private let cacheLifetime: TimeInterval = 3 * 24 * 60 * 60

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
        let oldestDailyDate = DailyDateHelper.todayString(timeZone: .gmt,
                                                          now: Date().addingTimeInterval(-cacheLifetime))

        try await DailyContent.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$generatedDate <= oldestDailyDate)
            .delete()

        if let entry = try await findEntry(kind: kind, userID: userID, date: today, database: database) {
            return try DailyContentDTOMapper.map(entry: entry)
        }

        return try await database.generationLock("daily:\(userID.uuidString):\(kind.rawValue):\(today)") { database in
            if let entry = try await findEntry(kind: kind, userID: userID, date: today, database: database) {
                return try DailyContentDTOMapper.map(entry: entry)
            }

            let text = try await generateText(kind: kind, user: user, req: req)
            let entry = DailyContent(userID: userID, kind: kind, text: text, generatedDate: today)

            try await entry.save(on: database)
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
