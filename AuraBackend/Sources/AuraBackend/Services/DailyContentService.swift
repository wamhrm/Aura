//
//  DailyContentService.swift
//  AuraServer
//
//  Created by ddorsat on 26.05.2026.
//

import Fluent
import Vapor

struct DailyContentService {
    private let openAIService = OpenAIService()

    func getOrGenerateDailyInsight(for user: User, req: Request, on database: any Database) async throws -> DailyInsightDTO {
        try await getOrGenerate(kind: .insight,
                                for: user,
                                req: req,
                                on: database,
                                map: DailyContentDTOMapper.mapInsight)
    }

    func getOrGenerateDailyTip(for user: User, req: Request, on database: any Database) async throws -> DailyTipDTO {
        try await getOrGenerate(kind: .tip,
                                for: user,
                                req: req,
                                on: database,
                                map: DailyContentDTOMapper.mapTip)
    }

    private func getOrGenerate<T>(kind: DailyContentKind,
                                  for user: User,
                                  req: Request,
                                  on database: any Database,
                                  map: (DailyContent) throws -> T) async throws -> T {
        guard hasCompletedProfileInfo(user) else {
            throw Abort(.badRequest, reason: "Заполните профиль перед получением контента дня")
        }

        let userID = try user.requireID()
        let today = DailyDateHelper.todayString()

        if let entry = try await DailyContent.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$kind == kind.rawValue)
            .first(),
           DailyDateHelper.isToday(entry.generatedDate) {
            return try map(entry)
        }

        let generatedText = try await generateText(kind: kind, for: user, req: req)
        let entry = try await upsertEntry(kind: kind,
                                          userID: userID,
                                          text: generatedText,
                                          generatedDate: today,
                                          on: database)

        return try map(entry)
    }

    private func generateText(kind: DailyContentKind, for user: User, req: Request) async throws -> String {
        switch kind {
            case .insight:
                return try await openAIService.makeDailyInsight(for: user, req: req)
            case .tip:
                return try await openAIService.makeDailyTip(for: user, req: req)
        }
    }

    private func upsertEntry(kind: DailyContentKind,
                             userID: User.IDValue,
                             text: String,
                             generatedDate: String,
                             on database: any Database) async throws -> DailyContent {
        if let existing = try await DailyContent.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$kind == kind.rawValue)
            .first() {
            existing.text = text
            existing.generatedDate = generatedDate
            try await existing.save(on: database)
            return existing
        }

        let entry = DailyContent(userID: userID,
                                 kind: kind,
                                 text: text,
                                 generatedDate: generatedDate)
        try await entry.save(on: database)
        
        return entry
    }

    private func hasCompletedProfileInfo(_ user: User) -> Bool {
        user.dateOfBirth != nil &&
        user.gender != nil &&
        user.socialType != nil &&
        user.conflictStyle != nil &&
        user.emotionalCore != nil &&
        user.decisionStyle != nil &&
        user.coreFocus != nil
    }
}
