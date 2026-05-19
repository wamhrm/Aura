import Foundation
import Vapor

struct HistoryItemDTO: Content {
    let id: UUID
    let kind: TestKind
    let createdAt: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let zodiacSign: String
}

struct HistoryItemDetailsDTO: Content {
    let id: UUID
    let kind: TestKind
    let createdAt: String
    let result: PersonalityResultDTO
}

enum HistoryDTOMapper {
    private static func createdAtString(from date: Date?) -> String {
        guard let date else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func listItem(from history: History) throws -> HistoryItemDTO {
        switch history.kind {
            case .personality:
                let result = try decodePersonalityResult(from: history.result)

                return HistoryItemDTO(id: try history.requireID(),
                                      kind: history.kind,
                                      createdAt: createdAtString(from: history.createdAt),
                                      selectedTests: history.selectedTests,
                                      archetypeTitle: result.archetypeTitle,
                                      archetypeSubtitle: result.archetypeSubtitle,
                                      zodiacSign: result.zodiacSign)
            case .compatibility:
                throw Abort(.notImplemented, reason: "История совместимости пока недоступна")
        }
    }

    static func detail(from history: History) throws -> HistoryItemDetailsDTO {
        switch history.kind {
            case .personality:
                let result = try decodePersonalityResult(from: history.result)

                return HistoryItemDetailsDTO(id: try history.requireID(),
                                             kind: history.kind,
                                             createdAt: createdAtString(from: history.createdAt),
                                             result: result)
            case .compatibility:
                throw Abort(.notImplemented, reason: "История совместимости пока недоступна")
        }
    }

    private static func decodePersonalityResult(from resultJSON: String) throws -> PersonalityResultDTO {
        guard let data = resultJSON.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Некорректная запись истории")
        }

        return try JSONDecoder().decode(PersonalityResultDTO.self, from: data)
    }
}
