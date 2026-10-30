//
//  OpenAIDTOs.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Vapor

struct OpenAIChatDTO: Encodable {
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

struct OpenAIResponseFormat: Encodable {
    let type = "json_schema"
    let jsonSchema: OpenAIJSONSchema

    init(name: String, schema: JSONSchema) {
        self.jsonSchema = OpenAIJSONSchema(name: name, strict: true, schema: schema)
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }
}

struct OpenAIJSONSchema: Encodable {
    let name: String
    let strict: Bool
    let schema: JSONSchema
}

indirect enum JSONSchema: Encodable, Sendable {
    case object([(String, JSONSchema)])
    case array(JSONSchema)
    case string
    case integer
    case stringEnum([String])

    static let titledText = JSONSchema.object([("title", .string), ("description", .string)])

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: SchemaKey.self)

        switch self {
            case .object(let properties):
                try container.encode("object", forKey: "type")
                var nested = container.nestedContainer(keyedBy: SchemaKey.self, forKey: "properties")
                for (name, schema) in properties {
                    try nested.encode(schema, forKey: SchemaKey(stringValue: name))
                }
                try container.encode(properties.map(\.0), forKey: "required")
                try container.encode(false, forKey: "additionalProperties")
            case .array(let items):
                try container.encode("array", forKey: "type")
                try container.encode(items, forKey: "items")
            case .string:
                try container.encode("string", forKey: "type")
            case .integer:
                try container.encode("integer", forKey: "type")
            case .stringEnum(let values):
                try container.encode("string", forKey: "type")
                try container.encode(values, forKey: "enum")
        }
    }

    private struct SchemaKey: CodingKey, ExpressibleByStringLiteral {
        let stringValue: String
        let intValue: Int? = nil

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init(stringLiteral value: String) {
            self.stringValue = value
        }

        init?(intValue: Int) {
            return nil
        }
    }
}

struct OpenAIChatResponse: Content {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Content {
    let message: OpenAIResponseMessage
    let finishReason: String?

    private enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct OpenAIResponseMessage: Content {
    let content: String?
    let refusal: String?
}

struct OpenAIErrorResponse: Content {
    let error: OpenAIError
}

struct OpenAIError: Content {
    let message: String
}
