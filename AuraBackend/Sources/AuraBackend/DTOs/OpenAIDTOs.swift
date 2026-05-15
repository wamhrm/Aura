import Vapor

struct OpenAIChatRequest: Content {
    let model: String
    let messages: [OpenAIMessage]
    let responseFormat: OpenAIResponseFormat

    private enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

struct OpenAIMessage: Content {
    let role: String
    let content: String
}

struct OpenAIResponseFormat: Content {
    let type: String
}

struct OpenAIChatResponse: Content {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Content {
    let message: OpenAIMessage
}

struct OpenAIErrorResponse: Content {
    let error: OpenAIError
}

struct OpenAIError: Content {
    let message: String
}
