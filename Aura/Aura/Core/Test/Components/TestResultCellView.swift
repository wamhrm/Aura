//
//  TestResultsCellView.swift
//  Aura
//
//  Created by wamhrm on 12.05.2026.
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
    case natalChart, planetaryAspects
    
    // Поведенческие паттерны
    case socialFilter, energyDrain
    
    // Стиль принятия решений
    case logicBalance, intuitionFactor
    
    // Стиль привязанности
    case autonomyNeed, securityBase
    
    // Идеальный партнер
    case intellectualMatch, emotionalDepth

    // Язык любви
    case loveExpression, emotionalNeeds

    var title: String {
        switch self {
            case .natalChart: "Анализ натальной карты"
            case .planetaryAspects: "Планетарные аспекты"
            case .socialFilter: "Социальный фильтр"
            case .energyDrain: "Источник истощения"
            case .logicBalance: "Баланс логики"
            case .intuitionFactor: "Фактор интуиции"
            case .autonomyNeed: "Потребность в автономии"
            case .securityBase: "База безопасности"
            case .intellectualMatch: "Интеллектуальная схожесть"
            case .emotionalDepth: "Глубина связи"
            case .loveExpression: "Способы проявления чувств"
            case .emotionalNeeds: "Эмоциональные потребности"
        }
    }

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
    case synastry, karmicLesson
    
    // Паттерны отношений
    case dominanceDynamics, emotionalResonance
    
    // Стили привязанности
    case attachmentBond, comfortDistance
    
    // Языки любви
    case languageMatch, translationNeeds
    
    // Конфликты и примирение
    case conflictMechanics, peaceRecovery
    
    var title: String {
        switch self {
            case .synastry: "Синастрия знаков"
            case .karmicLesson: "Кармический урок"
            case .dominanceDynamics: "Динамика лидерства"
            case .emotionalResonance: "Эмоциональный резонанс"
            case .attachmentBond: "Сцепка типов"
            case .comfortDistance: "Дистанция комфорта"
            case .languageMatch: "Совпадение языков"
            case .translationNeeds: "Трудности перевода"
            case .conflictMechanics: "Механика ссор"
            case .peaceRecovery: "Скорость примирения"
        }
    }

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
        }
    }
}

#Preview {
    TestResultCellView(test: CompatibilityCellTypes.comfortDistance,
                       description: "Понятная работа настала")
        .padding(.horizontal)
}
