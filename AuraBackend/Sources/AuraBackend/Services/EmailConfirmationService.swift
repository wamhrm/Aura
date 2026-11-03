//
//  EmailConfirmationService.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct EmailConfirmationService {
    private let codeLifetime: TimeInterval = 15 * 60
    private let resendInterval: TimeInterval = 60
    private let limitWindow: TimeInterval = 24 * 60 * 60
    private let dailyLimit = 5
    private let maxAttempts = 5
    private let emailService = EmailService()

    func sendCode(to user: User, req: Request) async throws {
        guard !user.isEmailConfirmed, let email = user.email else { return }
        let userID = try user.requireID()

        try await EmailConfirmation.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt < Date().addingTimeInterval(-limitWindow))
            .delete()

        let recentCodes = try await EmailConfirmation.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        if let lastSentAt = recentCodes.first?.createdAt, Date().timeIntervalSince(lastSentAt) < resendInterval {
            throw Abort(.tooManyRequests, reason: "Код уже отправлен. Запросить новый можно через минуту")
        }

        guard recentCodes.count < dailyLimit else {
            throw Abort(.tooManyRequests, reason: "Слишком много запросов. Попробуйте завтра")
        }

        let code = (0..<PasswordResetService.codeLength).map { _ in String(Int.random(in: 0...9)) }.joined()
        let confirmation = EmailConfirmation(userID: userID,
                                             codeHash: hash(code, userID: userID),
                                             expiresAt: Date().addingTimeInterval(codeLifetime))
        try await confirmation.save(on: req.db)

        do {
            try await emailService.send(to: email,
                                        subject: "Код для подтверждения почты Aura",
                                        html: emailHTML(code: code),
                                        text: emailText(code: code),
                                        req: req)
        } catch {
            try? await confirmation.delete(on: req.db)
            throw error
        }
    }

    func confirm(_ code: String, for user: User, req: Request) async throws {
        guard !user.isEmailConfirmed else { return }
        let userID = try user.requireID()

        guard let confirmation = try await EmailConfirmation.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .first(),
              confirmation.expiresAt > Date()
        else { throw Abort(.badRequest, reason: "Код недействителен. Запросите новый") }

        // Takes the attempt in one statement, so parallel requests can't get more than maxAttempts checks
        let confirmationID = try confirmation.requireID()
        let takenAttempts = try await req.db.sql()
            .raw("UPDATE email_confirmations SET attempts = attempts + 1 WHERE id = \(bind: confirmationID) AND attempts < \(bind: maxAttempts) RETURNING id")
            .all()

        guard !takenAttempts.isEmpty else {
            throw Abort(.tooManyRequests, reason: "Слишком много попыток. Запросите новый код")
        }

        guard confirmation.codeHash == hash(code, userID: userID) else {
            throw Abort(.badRequest, reason: "Неверный код")
        }

        user.emailConfirmedAt = Date()

        try await req.db.transaction { database in
            try await user.save(on: database)
            try await EmailConfirmation.query(on: database).filter(\.$user.$id == userID).delete()
        }
    }

    private func hash(_ code: String, userID: UUID) -> String {
        SHA256.hash(data: Data("\(userID.uuidString):\(code)".utf8)).hex
    }

    private func emailText(code: String) -> String {
        """
        Ваш код для подтверждения почты в Aura: \(code)

        Код действует 15 минут. Если вы не регистрировались в Aura, просто проигнорируйте это письмо.
        """
    }

    private func emailHTML(code: String) -> String {
        """
        <div style="font-family: -apple-system, 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; color: #1c1c1e;">
          <h2 style="margin: 0 0 16px;">Подтверждение почты в Aura</h2>
          <p style="margin: 0 0 12px;">Ваш код для подтверждения почты:</p>
          <p style="margin: 0 0 16px; font-size: 32px; font-weight: 700; letter-spacing: 6px;">\(code)</p>
          <p style="margin: 0 0 8px; color: #6e6e73;">Код действует 15 минут.</p>
          <p style="margin: 0; color: #6e6e73;">Если вы не регистрировались в Aura, просто проигнорируйте это письмо.</p>
        </div>
        """
    }
}
