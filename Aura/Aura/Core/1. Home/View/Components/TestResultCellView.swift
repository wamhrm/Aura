//
//  TestResultsCellView.swift
//  Aura
//
//  Created by ddorsat on 12.05.2026.
//

import SwiftUI

protocol TestResultDisplayable: Hashable, CaseIterable {
    var icon: String { get }
    var title: String { get }
}

struct TestResultCellView<TestResult: TestResultDisplayable>: View {
    let test: TestResult
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(test.icon)
                
                Text(test.title)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            
            Text(description)
                .foregroundStyle(.deepGray)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum PersonalityCellTypes: String, TestResultDisplayable {
    // Поведенческие паттерны
    case socialFilter = "Социальный фильтр"
    case energyDrain = "Источник истощения"
    
    // Стиль принятия решений
    case logicBalance = "Баланс логики"
    case intuitionFactor = "Фактор интуиции"
    
    // Стиль привязанности
    case autonomyNeed = "Потребность в автономии"
    case securityBase = "База безопасности"
    
    // Идеальный партнер
    case intellectualMatch = "Интеллектуальная схожесть"
    case emotionalDepth = "Глубина связи"
    
    // Язык любви
    case primaryLanguage = "Основной язык"
    case secondaryLanguage = "Дополнительный язык"
    
    var title: String {
        return rawValue
    }

    var icon: String {
        switch self {
            case .socialFilter: return "🛡️"
            case .energyDrain: return "🔋"
            case .logicBalance: return "⚖️"
            case .intuitionFactor: return "🔮"
            case .autonomyNeed: return "🦅"
            case .securityBase: return "⚓"
            case .intellectualMatch: return "🧠"
            case .emotionalDepth: return "🌊"
            case .primaryLanguage: return "❤️"
            case .secondaryLanguage: return "💬"
        }
    }
}

enum CompatibilityCellTypes: String, TestResultDisplayable {
    // Астрология пары
    case synastry = "Синастрия знаков"
    case karmicLesson = "Кармический урок"
    
    // Паттерны отношений
    case dominanceDynamics = "Динамика лидерства"
    case emotionalResonance = "Эмоциональный резонанс"
    
    // Стили привязанности
    case attachmentBond = "Сцепка типов"
    case comfortDistance = "Дистанция комфорта"
    
    // Языки любви
    case languageMatch = "Совпадение языков"
    case translationNeeds = "Трудности перевода"
    
    // Конфликты и примирение
    case conflictMechanics = "Механика ссор"
    case peaceRecovery = "Скорость примирения"
    
    // Сексуальная совместимость
    case sexualTemperament = "Темперамент"
    case sexualChemistry = "Сексуальная химия"
    
    var title: String {
        return rawValue
    }

    var icon: String {
        switch self {
            case .synastry: return "🪐"
            case .karmicLesson: return "⚓"
            case .dominanceDynamics: return "👑"
            case .emotionalResonance: return "📻"
            case .attachmentBond: return "⛓️"
            case .comfortDistance: return "📏"
            case .languageMatch: return "🗣️"
            case .translationNeeds: return "📖"
            case .conflictMechanics: return "🧨"
            case .peaceRecovery: return "🏳️"
            case .sexualTemperament: return "🔥"
            case .sexualChemistry: return "🧪"
        }
    }
}

#Preview {
    TestResultCellView(test: CompatibilityCellTypes.attachmentBond, description: "Понятная работа настала")
}
