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
        VStack(alignment: .leading, spacing: Adaptive.size(10, 10, 12)) {
            HStack {
                Text(test.icon)
                    .font(Adaptive.size(.default, .system(size: 18), .system(size: 19)))
                
                Text(test.title)
                    .font(.system(size: Adaptive.size(14, 15, 15)))
                    .fontWeight(.semibold)
            }
            
            Text(description)
                .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
                .foregroundStyle(.deepGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum PersonalityCellTypes: String, TestResultDisplayable, Codable {
    case natalChart, planetaryAspects, socialFilter, energyDrain, logicBalance, intuitionFactor, autonomyNeed, securityBase, intellectualMatch, emotionalDepth, loveExpression, emotionalNeeds

    var title: String {
        switch self {
            case .natalChart: AppLanguage.text("Черты вашего знака")
            case .planetaryAspects: AppLanguage.text("Знак и ваш характер")
            case .socialFilter: AppLanguage.text("Социальный фильтр")
            case .energyDrain: AppLanguage.text("Источник истощения")
            case .logicBalance: AppLanguage.text("Баланс логики")
            case .intuitionFactor: AppLanguage.text("Фактор интуиции")
            case .autonomyNeed: AppLanguage.text("Потребность в автономии")
            case .securityBase: AppLanguage.text("База безопасности")
            case .intellectualMatch: AppLanguage.text("Интеллектуальная схожесть")
            case .emotionalDepth: AppLanguage.text("Глубина связи")
            case .loveExpression: AppLanguage.text("Способы проявления чувств")
            case .emotionalNeeds: AppLanguage.text("Эмоциональные потребности")
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
    case synastry, karmicLesson, dominanceDynamics, emotionalResonance, attachmentBond, comfortDistance, languageMatch, translationNeeds, conflictMechanics, peaceRecovery, sexualTemperament, sexualChemistry
    
    var title: String {
        switch self {
            case .synastry: AppLanguage.text("Совместимость знаков")
            case .karmicLesson: AppLanguage.text("Кармический урок")
            case .dominanceDynamics: AppLanguage.text("Динамика лидерства")
            case .emotionalResonance: AppLanguage.text("Эмоциональный резонанс")
            case .attachmentBond: AppLanguage.text("Сцепка типов")
            case .comfortDistance: AppLanguage.text("Дистанция комфорта")
            case .languageMatch: AppLanguage.text("Совпадение языков")
            case .translationNeeds: AppLanguage.text("Трудности перевода")
            case .conflictMechanics: AppLanguage.text("Механика ссор")
            case .peaceRecovery: AppLanguage.text("Скорость примирения")
            case .sexualTemperament: AppLanguage.text("Сексуальный темперамент")
            case .sexualChemistry: AppLanguage.text("Сексуальная химия")
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
            case .sexualTemperament: "🔥"
            case .sexualChemistry: "🧪"
        }
    }
}

#Preview {
    TestResultCellView(test: CompatibilityCellTypes.comfortDistance,
                       description: AppLanguage.text("Понятная работа настала"))
        .padding(.horizontal)
}
