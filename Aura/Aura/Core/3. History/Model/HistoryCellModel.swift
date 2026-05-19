import Foundation

struct HistoryCellModel: Decodable, Identifiable, Hashable {
    let id: UUID
    let createdAt: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let zodiacSign: String
}

struct HistoryCellDetailsModel: Decodable {
    let id: UUID
    let createdAt: String
    let result: PersonalityResultModel
}
