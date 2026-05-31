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
        VStack(alignment: .leading, spacing: Adaptive.size(10, 12)) {
            HStack {
                Text(test.icon)
                    .font(Adaptive.size(.default, .system(size: 19)))
                
                Text(test.title)
                    .font(.system(size: Adaptive.size(14, 15)))
                    .fontWeight(.semibold)
            }
            
            Text(description)
                .font(Adaptive.size(.footnote, .system(size: 14)))
                .foregroundStyle(.deepGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum PersonalityCellTypes: String, TestResultDisplayable, Codable {
    // Астрология
    case natalChart = "Анализ натальной карты"
    case planetaryAspects = "Планетарные аспекты"
    
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
    case loveExpression = "Способы проявления чувств"
    case emotionalNeeds = "Эмоциональные потребности"

    var title: String { rawValue }

    var icon: String {
        switch self {
            case .socialFilter: "🛡️"
            case .energyDrain: "🔋"
            case .logicBalance: "⚖️"
            case .intuitionFactor: "🔮"
            case .autonomyNeed: "🦅"
            case .securityBase: "⚓"
            case .intellectualMatch: "🧠"
            case .emotionalDepth: "🌊"
            case .natalChart: "✨"
            case .planetaryAspects: "🪐"
            case .loveExpression: "💝"
            case .emotionalNeeds: "💗"
        }
    }
}

enum CompatibilityCellTypes: String, TestResultDisplayable, Codable {
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
    case sexualTemperament = "Сексуальный темперамент"
    case sexualChemistry = "Сексуальная химия"
    
    var title: String { rawValue }

    var icon: String {
        switch self {
            case .synastry: "🪐"
            case .karmicLesson: "⚓"
            case .dominanceDynamics: "👑"
            case .emotionalResonance: "📻"
            case .attachmentBond: "⛓️"
            case .comfortDistance: "📏"
            case .languageMatch: "🗣️"
            case .translationNeeds: "📖"
            case .conflictMechanics: "🧨"
            case .peaceRecovery: "🏳️"
            case .sexualTemperament: "🔥"
            case .sexualChemistry: "🧪"
        }
    }
}

#Preview {
    TestResultCellView(test: CompatibilityCellTypes.comfortDistance,
                       description: "Понятная работа настала")
        .padding(.horizontal)
}
