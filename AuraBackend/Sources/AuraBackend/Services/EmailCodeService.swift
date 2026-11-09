//
//  EmailCodeService.swift
//  AuraBackend
//
//  Created by wamhrm on 09.11.2026.
//

import Fluent
import Vapor

struct EmailCodeService {
    private let codeLength = 6
    private let codeLifetime: TimeInterval = 15 * 60
    private let resendInterval: TimeInterval = 60
    private let limitWindow: TimeInterval = 24 * 60 * 60
    private let dailyLimit = 5
    private let maxAttempts = 5
    private let emailService = EmailService()

    func sendConfirmation(user: User, req: Request) async throws {
        guard !user.isEmailConfirmed, let email = user.email else { return }
        let userID = try user.requireID()

        let code = makeCode()
        let confirmation = try await saveConfirmation(userID: userID, code: code, database: req.db)

        do {
            try await emailService.send(recipient: email,
                                        subject: "Код для подтверждения почты Aura",
                                        html: confirmationHTML(code: code),
                                        text: confirmationText(code: code),
                                        req: req)
        } catch {
            try? await confirmation.delete(on: req.db)
            throw error
        }
    }

    func confirm(code: String, user: User, req: Request) async throws {
        guard !user.isEmailConfirmed else { return }
        let userID = try user.requireID()

        guard let confirmation = try await EmailConfirmation.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .first(),
              confirmation.expiresAt > Date()
        else { throw Abort(.badRequest, reason: "Код недействителен. Запросите новый") }

        try takeAttempt(attempts: confirmation.attempts)
        confirmation.attempts += 1
        try await confirmation.save(on: req.db)

        guard confirmation.codeHash == hash(code: code, userID: userID) else {
            throw Abort(.badRequest, reason: "Неверный код")
        }

        user.emailConfirmedAt = Date()
        try await user.save(on: req.db)
        try await EmailConfirmation.query(on: req.db).filter(\.$user.$id == userID).delete()
    }

    func sendReset(user: User, req: Request) async throws {
        guard let email = user.email else { return }
        let userID = try user.requireID()

        let code = makeCode()
        let reset = try await saveReset(userID: userID, code: code, database: req.db)

        do {
            try await emailService.send(recipient: email,
                                        subject: "Код для сброса пароля Aura",
                                        html: resetHTML(code: code),
                                        text: resetText(code: code),
                                        req: req)
        } catch {
            try? await reset.delete(on: req.db)
            throw error
        }
    }

    func verifyReset(code: String, user: User, req: Request) async throws {
        let userID = try user.requireID()

        guard let reset = try await PasswordReset.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .first(),
              reset.expiresAt > Date()
        else { throw Abort(.badRequest, reason: "Код недействителен. Запросите новый") }

        try takeAttempt(attempts: reset.attempts)
        reset.attempts += 1
        try await reset.save(on: req.db)

        guard reset.codeHash == hash(code: code, userID: userID) else {
            throw Abort(.badRequest, reason: "Неверный код")
        }
    }

    private func saveConfirmation(userID: UUID, code: String, database: any Database) async throws -> EmailConfirmation {
        try await EmailConfirmation.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt < Date().addingTimeInterval(-limitWindow))
            .delete()

        let recentCodes = try await EmailConfirmation.query(on: database)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        try checkSendLimit(createdAt: recentCodes.compactMap(\.createdAt))

        let confirmation = EmailConfirmation(userID: userID,
                                             codeHash: hash(code: code, userID: userID),
                                             expiresAt: Date().addingTimeInterval(codeLifetime))
        try await confirmation.save(on: database)
        return confirmation
    }

    private func saveReset(userID: UUID, code: String, database: any Database) async throws -> PasswordReset {
        try await PasswordReset.query(on: database)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt < Date().addingTimeInterval(-limitWindow))
            .delete()

        let recentResets = try await PasswordReset.query(on: database)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        try checkSendLimit(createdAt: recentResets.compactMap(\.createdAt))

        let reset = PasswordReset(userID: userID,
                                  codeHash: hash(code: code, userID: userID),
                                  expiresAt: Date().addingTimeInterval(codeLifetime))
        try await reset.save(on: database)
        return reset
    }

    private func checkSendLimit(createdAt: [Date]) throws {
        if let lastSentAt = createdAt.first, Date().timeIntervalSince(lastSentAt) < resendInterval {
            throw Abort(.tooManyRequests, reason: "Код уже отправлен. Запросить новый можно через минуту")
        }

        guard createdAt.count < dailyLimit else {
            throw Abort(.tooManyRequests, reason: "Слишком много запросов. Попробуйте завтра")
        }
    }

    private func takeAttempt(attempts: Int) throws {
        guard attempts < maxAttempts else {
            throw Abort(.tooManyRequests, reason: "Слишком много попыток. Запросите новый код")
        }
    }

    private func makeCode() -> String {
        (0..<codeLength).map { _ in String(Int.random(in: 0...9)) }.joined()
    }

    private func hash(code: String, userID: UUID) -> String {
        SHA256.hash(data: Data("\(userID.uuidString):\(code)".utf8)).hex
    }

    private func confirmationText(code: String) -> String {
        """
        Ваш код для подтверждения почты в Aura: \(code)

        Код действует 15 минут. Если вы не регистрировались в Aura, просто проигнорируйте это письмо.
        """
    }

    private func confirmationHTML(code: String) -> String {
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

    private func resetText(code: String) -> String {
        """
        Ваш код для сброса пароля в Aura: \(code)

        Код действует 15 минут. Если вы не запрашивали сброс пароля, просто проигнорируйте это письмо.
        """
    }

    private func resetHTML(code: String) -> String {
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
