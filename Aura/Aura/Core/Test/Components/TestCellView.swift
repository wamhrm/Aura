//
//  TestCellView.swift
//  Aura
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

protocol TestCellDisplayable: Hashable, CaseIterable {
    var title: String { get }
    var description: String { get }
    var icon: String { get }
    var color: UIColor { get }
    var deepDescription: String { get }
    var includedItems: [String] { get }
}

struct TestCellView<Test: TestCellDisplayable>: View {
    let type: Test
    @Binding var hasChosenTest: Bool
    let onSelectionToggle: () -> Void
    let onTapHandler: () -> Void
    
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        Button(action: onTapHandler) {
            HStack(spacing: 15) {
                HStack(spacing: 15) {
                    TestCellImage(icon: type.icon, color: type.color, iconSize: .title2, backgroundSize: Adaptive.size(43, 45), isResults: false)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(type.title)
                            .font(Adaptive.size(.footnote, .system(size: 14)))
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)

                        Text(type.description)
                            .font(Adaptive.size(.caption, .footnote))
                            .fontWeight(.medium)
                            .foregroundStyle(.deepGray)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                onSelectionToggle()
            } label: {
                Circle()
                    .fill(hasChosenTest ? AccentColorOption.color(accentColor).opacity(0.85) : .clear)
                    .frame(width: Adaptive.size(23, 25),
                           height: Adaptive.size(23, 25))
                    .overlay(Circle().stroke(Color.fieldBackground, lineWidth: 2))
                    .overlay {
                        Circle()
                            .fill(.cardBackground)
                            .frame(width: Adaptive.size(8, 10),
                                   height: Adaptive.size(8, 10))
                    }
                    .padding(.trailing, 5)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(12, .cardBackground, true)
        .foregroundStyle(.primaryText)
    }
}

enum PersonalityTestTypes: String, TestCellDisplayable, Codable {
    case astrology = "Астрология"
    case behavioralPatterns = "Поведенческие паттерны"
    case decisionMaking = "Стиль принятия решений"
    case attachmentStyle = "Стиль привязанности"
    case idealPartner = "Идеальный партнер"
    case loveLanguage = "Язык любви"

    var title: String { rawValue }

    var description: String {
        switch self {
            case .astrology: "Узнайте силу ваших планет"
            case .behavioralPatterns: "Разберите свои реакции"
            case .decisionMaking: "Поймите, как вы выбираете"
            case .attachmentStyle: "Определите ваш стиль отношений"
            case .idealPartner: "Соберите портрет партнера"
            case .loveLanguage: "Как вы выражаете любовь?"
        }
    }

    var icon: String {
        switch self {
            case .astrology: "sparkles"
            case .behavioralPatterns: "figure.walk.motion"
            case .decisionMaking: "brain.head.profile"
            case .attachmentStyle: "person.2"
            case .idealPartner: "heart.text.square"
            case .loveLanguage: "heart"
        }
    }

    var color: UIColor {
        switch self {
            case .astrology: .systemIndigo
            case .behavioralPatterns: .systemTeal
            case .decisionMaking: .systemBlue
            case .attachmentStyle: .systemOrange
            case .idealPartner: .systemPurple
            case .loveLanguage: .systemRed
        }
    }

    var deepDescription: String {
        switch self {
            case .astrology: "Получите подробный разбор вашей натальной карты: положение планет, сильные стороны личности, внутренние конфликты и природные склонности. Поймёте, что влияет на ваши решения и поведение."
            case .behavioralPatterns: "Разберите повторяющиеся сценарии поведения: как вы реагируете на стресс, близость, неопределенность и эмоциональное напряжение."
            case .decisionMaking: "Поймите, что сильнее влияет на ваши решения: эмоции, логика, интуиция или потребность в стабильности. Это поможет выбирать спокойнее и увереннее."
            case .attachmentStyle: "Определите свой стиль привязанности и разберите модели поведения в отношениях. Узнаете, почему вы реагируете определённым образом и какие сценарии повторяются чаще всего."
            case .idealPartner: "Соберите понятный портрет партнера, который подходит вашему темпераменту, эмоциональным потребностям и ожиданиям от близости."
            case .loveLanguage: "Поймите, как вы выражаете любовь и что делает вас эмоционально удовлетворённым в отношениях. Это поможет лучше понимать себя и избегать типичных недопониманий."
        }
    }

    var includedItems: [String] {
        switch self {
            case .astrology: ["Анализ натальной карты",
                        "Планетарные аспекты",
                        "Сильные и слабые стороны",
                        "Личностные особенности"]
            case .behavioralPatterns: ["Повторяющиеся реакции",
                        "Поведение в стрессе",
                        "Социальные сценарии",
                        "Зоны личного роста"]
            case .decisionMaking: ["Стиль выбора",
                        "Роль эмоций и логики",
                        "Реакция на неопределенность",
                        "Риски импульсивности"]
            case .attachmentStyle: ["Тип привязанности",
                        "Поведение в отношениях",
                        "Триггеры и страхи",
                        "Зоны личного роста"]
            case .idealPartner: ["Эмоциональные потребности",
                        "Подходящий темперамент",
                        "Важные границы",
                        "Портрет партнера"]
            case .loveLanguage: ["Ваш язык любви",
                        "Способы проявления чувств",
                        "Эмоциональные потребности",
                        "Ошибки в коммуникации"]
        }
    }
}

enum CompatibilityTestTypes: String, TestCellDisplayable, Codable {
    case astrology = "Астрология пары"
    case behavioralPatterns = "Поведенческие паттерны"
    case attachmentCompatibility = "Стили привязанности"
    case loveLanguages = "Языки любви"
    case conflictResolution = "Конфликты и примирение"
    case sexualCompatibility = "Сексуальная совместимость"

    var title: String { rawValue }

    var description: String {
        switch self {
            case .astrology: "Общая динамика"
            case .behavioralPatterns: "Как вы ведете себя"
            case .attachmentCompatibility: "Безопасность и дистанция"
            case .loveLanguages: "Как вы даете и принимаете любовь"
            case .conflictResolution: "Триггеры и ссоры"
            case .sexualCompatibility: "Химия и интимные ожидания"
        }
    }

    var icon: String {
        switch self {
            case .astrology: "sparkles"
            case .behavioralPatterns: "person.2.wave.2"
            case .attachmentCompatibility: "lock.heart"
            case .loveLanguages: "heart"
            case .conflictResolution: "bubble.left.and.bubble.right"
            case .sexualCompatibility: "flame"
        }
    }

    var color: UIColor {
        switch self {
            case .astrology: .systemIndigo
            case .behavioralPatterns: .systemTeal
            case .attachmentCompatibility: .systemOrange
            case .loveLanguages: .systemRed
            case .conflictResolution: .systemBlue
            case .sexualCompatibility: .systemPink
        }
    }

    var deepDescription: String {
        switch self {
            case .astrology: "Сравните ваши натальные показатели и узнайте, где между вами возникает легкость, напряжение, притяжение и долгосрочный потенциал."
            case .behavioralPatterns: "Разберите, как ваши привычные реакции сочетаются в паре: кто сближается, кто отдаляется, где возникает поддержка, а где недопонимание."
            case .attachmentCompatibility: "Поймите, насколько ваши стили привязанности подходят друг другу и какие сценарии могут создавать тревогу, холодность или ощущение безопасности."
            case .loveLanguages: "Сравните ваши способы проявлять любовь, принимать заботу и чувствовать значимость в отношениях."
            case .conflictResolution: "Узнайте, как вы оба ведете себя в конфликте, какие триггеры усиливают ссоры и какие способы примирения подходят вашей паре."
            case .sexualCompatibility: "Исследуйте уровень интимной совместимости: желания, ожидания и скрытые несовпадения. Поймёте, где возникает напряжение и как усилить химию между вами."
        }
    }

    var includedItems: [String] {
        switch self {
            case .astrology: ["Синастрия пары",
                        "Солнце, Луна и Венера",
                        "Точки притяжения",
                        "Потенциал отношений"]
            case .behavioralPatterns: ["Реакции в близости",
                        "Поведение в стрессе",
                        "Роли в отношениях",
                        "Повторяющиеся сценарии"]
            case .attachmentCompatibility: ["Стили привязанности",
                        "Потребность в дистанции",
                        "Тревожные триггеры",
                        "Чувство безопасности"]
            case .loveLanguages: ["Языки любви пары",
                        "Способы заботы",
                        "Ожидания от партнера",
                        "Эмоциональная связь"]
            case .conflictResolution: ["Типичные конфликты",
                        "Триггеры напряжения",
                        "Стратегии примирения",
                        "Зоны договоренностей"]
            case .sexualCompatibility: ["Уровень влечения",
                        "Интимные ожидания",
                        "Совпадение желаний",
                        "Потенциал химии"]
        }
    }
}

#Preview {
    TestCellView(type: CompatibilityTestTypes.astrology, hasChosenTest: .constant(false)) {

    } onTapHandler: {

    }
    .padding(.horizontal)
}
