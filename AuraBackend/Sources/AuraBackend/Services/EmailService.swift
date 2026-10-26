//
//  EmailService.swift
//  AuraBackend
//
//  Created by ddorsat on 27.10.2026.
//

import Vapor

struct EmailService {
    private let baseURL = Environment.get("RESEND_BASE_URL") ?? "https://api.resend.com"
    private let sender = Environment.get("RESEND_FROM") ?? "Aura <noreply@aurawamhrm.space>"

    func send(to recipient: String, subject: String, html: String, text: String, req: Request) async throws {
        guard let apiKey = Environment.get("RESEND_API_KEY") else {
            req.logger.error("Email is not configured: RESEND_API_KEY is missing")
            throw Abort(.serviceUnavailable, reason: "Отправка писем временно недоступна. Попробуйте позже")
        }

        let response: ClientResponse

        do {
            response = try await req.client.post(URI(string: baseURL + "/emails")) { request in
                request.timeout = .seconds(15)
                request.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
                try request.content.encode(ResendEmail(from: sender,
                                                       to: [recipient],
                                                       subject: subject,
                                                       html: html,
                                                       text: text))
            }
        } catch {
            req.logger.error("Resend request failed: \(error)")
            throw Abort(.badGateway, reason: "Не удалось отправить письмо. Попробуйте позже")
        }

        guard (200..<300).contains(response.status.code) else {
            let body = response.body.map { String(buffer: $0) } ?? ""
            req.logger.error("Resend failed with status \(response.status.code): \(body)")
            throw Abort(.badGateway, reason: "Не удалось отправить письмо. Попробуйте позже")
        }
    }
}

private struct ResendEmail: Content {
    let from: String
    let to: [String]
    let subject: String
    let html: String
    let text: String
}
