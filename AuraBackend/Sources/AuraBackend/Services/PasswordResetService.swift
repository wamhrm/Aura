//
//  PasswordResetService.swift
//  AuraBackend
//
//  Created by ddorsat on 27.10.2026.
//

import Fluent
import Vapor

struct PasswordResetService {
    private let codeLifetime: TimeInterval = 15 * 60
    private let resendInterval: TimeInterval = 60
    private let limitWindow: TimeInterval = 24 * 60 * 60
    private let dailyLimit = 5
    private let maxAttempts = 5
    private let emailService = EmailService()

    func sendCode(to user: User, req: Request) async throws {
        guard let email = user.email else { return }
        let userID = try user.requireID()

        try await PasswordReset.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt < Date().addingTimeInterval(-limitWindow))
            .delete()

        let recentResets = try await PasswordReset.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        if let lastSentAt = recentResets.first?.createdAt, Date().timeIntervalSince(lastSentAt) < resendInterval {
            throw Abort(.tooManyRequests, reason: "Код уже отправлен. Запросить новый можно через минуту")
        }

        guard recentResets.count < dailyLimit else {
            throw Abort(.tooManyRequests, reason: "Слишком много запросов. Попробуйте завтра")
        }

        let code = (0..<6).map { _ in String(Int.random(in: 0...9)) }.joined()
        let reset = PasswordReset(userID: userID,
                                  codeHash: hash(code, userID: userID),
                                  expiresAt: Date().addingTimeInterval(codeLifetime))
        try await reset.save(on: req.db)

        do {
            try await emailService.send(to: email,
                                        subject: "Код для сброса пароля Aura",
                                        html: emailHTML(code: code),
                                        text: emailText(code: code),
                                        req: req)
        } catch {
            try? await reset.delete(on: req.db)
            throw error
        }
    }

    func verifyCode(_ code: String, for user: User, req: Request) async throws {
        let userID = try user.requireID()

        guard let reset = try await PasswordReset.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .first(),
              reset.expiresAt > Date()
        else { throw Abort(.badRequest, reason: "Код недействителен. Запросите новый") }

        guard reset.attempts < maxAttempts else {
            throw Abort(.tooManyRequests, reason: "Слишком много попыток. Запросите новый код")
        }

        guard reset.codeHash == hash(code, userID: userID) else {
            reset.attempts += 1
            try await reset.save(on: req.db)
            throw Abort(.badRequest, reason: "Неверный код")
        }
    }

    private func hash(_ code: String, userID: UUID) -> String {
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
