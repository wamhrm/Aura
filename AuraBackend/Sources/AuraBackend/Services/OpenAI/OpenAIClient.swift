//
//  OpenAIClient.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Foundation
import NIOCore
import Vapor

struct OpenAIClient {
    private let model = Environment.get("OPENAI_MODEL") ?? "gpt-5.4"
    private let maxCompletionTokens = 8_000
    private let requestTimeout: TimeAmount = .seconds(60)
    private let retryDelay: Duration = .seconds(1)
    private let retryableStatusCodes: Set<UInt> = [429, 500, 502, 503, 504]

    // Only transient HTTP errors get one retry. Invalid generated content is returned as an error.
    func generate<Result>(messages: [OpenAIMessage],
                          responseFormat: OpenAIResponseFormat,
                          req: Request,
                          parse: (Data) throws -> Result) async throws -> Result {
        let apiKey = try apiKey()
        let request = OpenAIChatDTO(model: model,
                                    messages: messages,
                                    responseFormat: responseFormat,
                                    maxCompletionTokens: maxCompletionTokens)

        var response = try await send(request: request, apiKey: apiKey, req: req)

        if retryableStatusCodes.contains(response.status.code) {
            req.logger.warning("OpenAI \(responseFormat.jsonSchema.name): HTTP \(response.status.code), retrying once")
            try await Task.sleep(for: retryDelay)
            response = try await send(request: request, apiKey: apiKey, req: req)
        }

        guard response.status == .ok else {
            let error = try? response.content.decode(OpenAIErrorResponse.self)
            req.logger.error("OpenAI request failed with status \(response.status.code): \(error?.error.message ?? "no error message")")
            throw Abort(.badGateway, reason: "OpenAI вернул ошибку")
        }

        guard let chatResponse = try? response.content.decode(OpenAIChatResponse.self),
              let choice = chatResponse.choices.first else {
            req.logger.error("OpenAI \(responseFormat.jsonSchema.name): the answer has no choices")
            throw emptyAnswerError
        }

        if let usage = chatResponse.usage {
            req.logger.info("OpenAI \(request.responseFormat.jsonSchema.name) used \(usage.promptTokens) prompt and \(usage.completionTokens) completion tokens")
        }

        if let refusal = choice.message.refusal {
            req.logger.warning("OpenAI refused to answer: \(refusal)")
            throw emptyAnswerError
        }

        guard choice.finishReason != "length", let content = choice.message.content else {
            req.logger.error("OpenAI \(responseFormat.jsonSchema.name): missing or incomplete content, finish reason: \(choice.finishReason ?? "none")")
            throw emptyAnswerError
        }

        do {
            return try parse(Data(content.utf8))
        } catch {
            req.logger.error("OpenAI \(responseFormat.jsonSchema.name): unexpected answer: \(error)")
            throw error as? Abort ?? OpenAIResultValidator.unexpectedFormatError
        }
    }

    private func send(request: OpenAIChatDTO, apiKey: String, req: Request) async throws -> ClientResponse {
        do {
            return try await req.client.post(URI(string: baseURL() + "/v1/chat/completions")) { clientRequest in
                clientRequest.timeout = requestTimeout
                clientRequest.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
                try clientRequest.content.encode(request, as: .json)
            }
        } catch let error as HTTPClientError where error == .deadlineExceeded {
            req.logger.error("OpenAI request timed out after \(requestTimeout)")
            throw Abort(.gatewayTimeout, reason: "OpenAI не ответил вовремя")
        }
    }

    private func apiKey() throws -> String {
        if let key = Environment.get("OPENAI_KEY"), !key.isEmpty {
            return key
        }

        throw Abort(.serviceUnavailable, reason: "OPENAI_KEY не задан")
    }

    private func baseURL() -> String {
        Environment.get("OPENAI_BASE_URL") ?? "https://api.openai.com"
    }

    private var emptyAnswerError: Abort {
        Abort(.badGateway, reason: "OpenAI вернул пустой ответ")
    }
}
