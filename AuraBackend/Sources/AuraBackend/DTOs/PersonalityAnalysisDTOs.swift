import Vapor

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

    static func from(title: String) -> PersonalityTestID? {
        allCases.first { $0.title == title }
    }

    static func from(titles: [String]) -> [PersonalityTestID]? {
        var mapped: [PersonalityTestID] = []

        for title in titles {
            guard let test = from(title: title) else { return nil }
            mapped.append(test)
        }

        return mapped
    }
}

struct PersonalityAnalysisResponse: Content {
    let name: String
    let zodiacSign: String
    let selectedTests: [String]
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityOverviewSection
    let emotionalBar: [PersonalityEmotionalBar]
    let sections: [PersonalityAnalysisResultSection]
}

struct PersonalityOverviewSection: Content, Codable {
    let title: String
    let description: String
}

struct PersonalityEmotionalBar: Content, Codable {
    let title: String
    let value: Int
}

struct PersonalityAnalysisResultSection: Content, Codable {
    let selectedTest: String
    let description: String
    let items: [PersonalityResultItem]
}

struct PersonalityResultItem: Content, Codable {
    let title: String
    let description: String
}

struct PersonalityAnalysisContent: Codable {
    let archetypeTitle: String
    let archetypeSubtitle: String
    let overview: PersonalityOverviewSection
    let emotionalBar: [PersonalityEmotionalBar]
    let sections: [PersonalityAnalysisResultSection]
}

enum PersonalityItemTitles {
    static let behavioralPatterns = ["Социальный фильтр", "Источник истощения"]
    static let decisionMaking = ["Баланс логики", "Фактор интуиции"]
    static let attachmentStyle = ["Потребность в автономии", "База безопасности"]
    static let idealPartner = ["Интеллектуальная схожесть", "Глубина связи"]
    static let astrology = ["Глубина связи", "Фактор интуиции"]
    static let loveLanguage = ["Глубина связи", "Интеллектуальная схожесть"]

    static func allowed(for test: PersonalityTestID) -> [String] {
        switch test {
            case .behavioralPatterns:
                return behavioralPatterns
            case .decisionMaking:
                return decisionMaking
            case .attachmentStyle:
                return attachmentStyle
            case .idealPartner:
                return idealPartner
            case .astrology:
                return astrology
            case .loveLanguage:
                return loveLanguage
        }
    }
}
