import Vapor

struct PersonalityAnalysisRequest: Content {
    let selectedTests: [PersonalityTestID]
}

enum PersonalityTestID: String, Content, CaseIterable {
    case astrology
    case behavioralPatterns
    case decisionMaking
    case attachmentStyle
    case idealPartner
    case loveLanguage

    var title: String {
        switch self {
            case .astrology:
                return "Астрология"
            case .behavioralPatterns:
                return "Поведенческие паттерны"
            case .decisionMaking:
                return "Стиль принятия решений"
            case .attachmentStyle:
                return "Стиль привязанности"
            case .idealPartner:
                return "Идеальный партнер"
            case .loveLanguage:
                return "Язык любви"
        }
    }
}

struct PersonalityAnalysisResponse: Content {
    let userName: String
    let zodiacSign: String?
    let selectedTests: [PersonalityTestID]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityTextSection
    let scales: [PersonalityScale]
    let sections: [PersonalityResultSection]
}

struct PersonalityAnalysisContent: Codable {
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityTextSection
    let scales: [PersonalityScale]
    let sections: [PersonalityResultSection]
}

struct PersonalityTextSection: Content {
    let title: String
    let body: String
}

struct PersonalityScale: Content {
    let title: String
    let value: Int
}

struct PersonalityResultSection: Content {
    let testID: PersonalityTestID
    let title: String
    let body: String
    let items: [PersonalityResultItem]
}

struct PersonalityResultItem: Content {
    let title: String
    let description: String
}
