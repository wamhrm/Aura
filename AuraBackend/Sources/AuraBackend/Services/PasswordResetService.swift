//
//  PasswordResetService.swift
//  AuraBackend
//
//  Created by wamhrm on 27.10.2026.
//

import Fluent
import FluentPostgresDriver
import Vapor

struct PasswordResetService {
    private let codeLength = 6

    private let codeLifetime: TimeInterval = 15 * 60
    private let resendInterval: TimeInterval = 60
    private let limitWindow: TimeInterval = 24 * 60 * 60
    private let dailyLimit = 5
    private let maxAttempts = 5
    private let emailService = EmailService()

    func sendCode(user: User, req: Request) async throws {
        guard let email = user.email else { return }
        let userID = try user.requireID()

        let code = (0..<codeLength).map { _ in String(Int.random(in: 0...9)) }.joined()
        let reset = try await req.db.transaction { database in
            try await database.sql().raw("SELECT id FROM users WHERE id = \(bind: userID) FOR UPDATE").run()

            try await PasswordReset.query(on: database)
                .filter(\.$user.$id == userID)
                .filter(\.$createdAt < Date().addingTimeInterval(-limitWindow))
                .delete()

            let recentResets = try await PasswordReset.query(on: database)
                .filter(\.$user.$id == userID)
                .sort(\.$createdAt, .descending)
                .all()

            if let lastSentAt = recentResets.first?.createdAt, Date().timeIntervalSince(lastSentAt) < resendInterval {
                throw Abort(.tooManyRequests, reason: "Код уже отправлен. Запросить новый можно через минуту")
            }

            guard recentResets.count < dailyLimit else {
                throw Abort(.tooManyRequests, reason: "Слишком много запросов. Попробуйте завтра")
            }

            let reset = PasswordReset(userID: userID,
                                      codeHash: hash(code: code, userID: userID),
                                      expiresAt: Date().addingTimeInterval(codeLifetime))
            try await reset.save(on: database)
            return reset
        }

        do {
            try await emailService.send(recipient: email,
                                        subject: "Код для сброса пароля Aura",
                                        html: emailHTML(code: code),
                                        text: emailText(code: code),
                                        req: req)
        } catch {
            try? await reset.delete(on: req.db)
            throw error
        }
    }

    func verifyCode(code: String, user: User, req: Request) async throws -> UUID {
        let userID = try user.requireID()

        guard let reset = try await PasswordReset.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .first(),
              reset.expiresAt > Date()
        else { throw Abort(.badRequest, reason: "Код недействителен. Запросите новый") }

        // Takes the attempt in one statement, so parallel requests can't get more than maxAttempts checks
        let resetID = try reset.requireID()
        let takenAttempts = try await req.db.sql()
            .raw("UPDATE password_resets SET attempts = attempts + 1 WHERE id = \(bind: resetID) AND attempts < \(bind: maxAttempts) RETURNING id")
            .all()

        guard !takenAttempts.isEmpty else {
            throw Abort(.tooManyRequests, reason: "Слишком много попыток. Запросите новый код")
        }

        guard reset.codeHash == hash(code: code, userID: userID) else {
            throw Abort(.badRequest, reason: "Неверный код")
        }

        return resetID
    }

    private func hash(code: String, userID: UUID) -> String {
        SHA256.hash(data: Data("\(userID.uuidString):\(code)".utf8)).hex
    }

    private func emailText(code: String) -> String {
        """
        Ваш код для сброса пароля в Aura: \(code)

        Код действует 15 минут. Если вы не запрашивали сброс пароля, просто проигнорируйте это письмо.
        """
    }

    private func emailHTML(code: String) -> String {
        """
        <div style="font-family: -apple-system, 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; color: #1c1c1e;">
          <h2 style="margin: 0 0 16px;">Сброс пароля в Aura</h2>
          <p style="margin: 0 0 12px;">Ваш код для сброса пароля:</p>
          <p style="margin: 0 0 16px; font-size: 32px; font-weight: 700; letter-spacing: 6px;">\(code)</p>
          <p style="margin: 0 0 8px; color: #6e6e73;">Код действует 15 минут.</p>
          <p style="margin: 0; color: #6e6e73;">Если вы не запрашивали сброс пароля, просто проигнорируйте это письмо.</p>
        </div>
        """
    }
}
