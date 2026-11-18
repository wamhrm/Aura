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

    func generate<Result>(messages: [OpenAIMessage],
                          responseFormat: OpenAIResponseFormat,
                          req: Request,
                          parse: (Data) throws -> Result) async throws -> Result {
        let apiKey = try apiKey()
        let request = OpenAIChatDTO(model: model,
                                    messages: messages,
                                    responseFormat: responseFormat,
                                    maxCompletionTokens: maxCompletionTokens)

        let operation = responseFormat.jsonSchema.name
        let response = try await send(request: request, apiKey: apiKey, req: req)

        guard response.status == .ok else {
            req.logger.error("OpenAI \(operation) failed with status \(response.status.code)")
            throw Abort(.badGateway, reason: "OpenAI вернул ошибку")
        }

        let chatResponse: OpenAIChatResponse
        do {
            chatResponse = try response.content.decode(OpenAIChatResponse.self)
        } catch {
            req.logger.error("OpenAI \(operation): response decoding failed: \(errorLogCode(error))")
            throw emptyAnswerError
        }

        guard let choice = chatResponse.choices.first else {
            req.logger.error("OpenAI \(operation): the answer has no choices")
            throw emptyAnswerError
        }

        if let usage = chatResponse.usage {
            req.logger.info("OpenAI \(operation) used \(usage.promptTokens) prompt and \(usage.completionTokens) completion tokens")
        }

        if choice.message.refusal != nil {
            req.logger.warning("OpenAI \(operation) refused to answer")
            throw emptyAnswerError
        }

        if choice.finishReason == "length" {
            req.logger.error("OpenAI \(operation): the answer reached the completion limit")
            throw emptyAnswerError
        }

        guard let content = choice.message.content else {
            req.logger.error("OpenAI \(operation): the answer has no content")
            throw emptyAnswerError
        }

        do {
            return try parse(Data(content.utf8))
        } catch {
            req.logger.error("OpenAI \(operation): unexpected answer: \(errorLogCode(error))")
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
