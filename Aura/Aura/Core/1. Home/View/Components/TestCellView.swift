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
    let showSelection: Bool
    @Binding var hasChosenTest: Bool
    let onSelectionToggle: (() -> Void)?
    let onTapHandler: () -> Void

    init(type: Test, showSelection: Bool, onTapHandler: @escaping () -> Void) {
        self.type = type
        self.showSelection = showSelection
        self._hasChosenTest = .constant(false)
        self.onSelectionToggle = nil
        self.onTapHandler = onTapHandler
    }

    init(type: Test,
         showSelection: Bool,
         hasChosenTest: Binding<Bool>,
         onSelectionToggle: @escaping () -> Void,
         onTapHandler: @escaping () -> Void) {
        self.type = type
        self.showSelection = showSelection
        self._hasChosenTest = hasChosenTest
        self.onSelectionToggle = onSelectionToggle
        self.onTapHandler = onTapHandler
    }

    var body: some View {
        Button(action: onTapHandler) {
            HStack(spacing: 15) {
                HStack(spacing: 15) {
                    Components.testCellImage(type.icon, type.color, .title2, 45, false)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(type.title)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)

                        Text(type.description)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.deepGray)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showSelection, let onSelectionToggle {
                Button {
                    onSelectionToggle()
                } label: {
                    Circle()
                        .fill(hasChosenTest ? .blue : .clear)
                        .frame(width: 25, height: 25)
                        .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 2))
                        .overlay {
                            Circle()
                                .fill(.white)
                                .frame(width: 10, height: 10)
                        }
                        .padding(.trailing, 5)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(15, true)
        .foregroundStyle(.black)
    }
}

enum TestType: String, TestCellDisplayable {
    case astrology = "Астрология"
    case behavioralPatterns = "Поведенческие паттерны"
    case decisionMaking = "Стиль принятия решений"
    case attachmentStyle = "Стиль привязанности"
    case idealPartner = "Идеальный партнер"
    case loveLanguage = "Язык любви"

    var title: String { rawValue }

    var description: String {
        switch self {
            case .astrology:
                return "Узнайте силу ваших планет"
            case .behavioralPatterns:
                return "Разберите свои реакции"
            case .decisionMaking:
                return "Поймите, как вы выбираете"
            case .attachmentStyle:
                return "Определите ваш стиль отношений"
            case .idealPartner:
                return "Соберите портрет партнера"
            case .loveLanguage:
                return "Как вы выражаете любовь?"
        }
    }

    var icon: String {
        switch self {
            case .astrology:
                return "sparkles"
            case .behavioralPatterns:
                return "figure.walk.motion"
            case .decisionMaking:
                return "brain.head.profile"
            case .attachmentStyle:
                return "person.2"
            case .idealPartner:
                return "heart.text.square"
            case .loveLanguage:
                return "heart"
        }
    }

    var color: UIColor {
        switch self {
            case .astrology:
                return .systemIndigo
            case .behavioralPatterns:
                return .systemTeal
            case .decisionMaking:
                return .systemBlue
            case .attachmentStyle:
                return .systemOrange
            case .idealPartner:
                return .systemPurple
            case .loveLanguage:
                return .systemRed
        }
    }

    var deepDescription: String {
        switch self {
            case .astrology:
                return "Получите подробный разбор вашей натальной карты: положение планет, сильные стороны личности, внутренние конфликты и природные склонности. Поймёте, что влияет на ваши решения и поведение."
            case .behavioralPatterns:
                return "Разберите повторяющиеся сценарии поведения: как вы реагируете на стресс, близость, неопределенность и эмоциональное напряжение."
            case .decisionMaking:
                return "Поймите, что сильнее влияет на ваши решения: эмоции, логика, интуиция или потребность в стабильности. Это поможет выбирать спокойнее и увереннее."
            case .attachmentStyle:
                return "Определите свой стиль привязанности и разберите модели поведения в отношениях. Узнаете, почему вы реагируете определённым образом и какие сценарии повторяются чаще всего."
            case .idealPartner:
                return "Соберите понятный портрет партнера, который подходит вашему темпераменту, эмоциональным потребностям и ожиданиям от близости."
            case .loveLanguage:
                return "Поймите, как вы выражаете любовь и что делает вас эмоционально удовлетворённым в отношениях. Это поможет лучше понимать себя и избегать типичных недопониманий."
        }
    }

    var includedItems: [String] {
        switch self {
            case .astrology:
                return ["Анализ натальной карты",
                        "Планетарные аспекты",
                        "Сильные и слабые стороны",
                        "Личностные особенности"]
            case .behavioralPatterns:
                return ["Повторяющиеся реакции",
                        "Поведение в стрессе",
                        "Социальные сценарии",
                        "Зоны личного роста"]
            case .decisionMaking:
                return ["Стиль выбора",
                        "Роль эмоций и логики",
                        "Реакция на неопределенность",
                        "Риски импульсивности"]
            case .attachmentStyle:
                return ["Тип привязанности",
                        "Поведение в отношениях",
                        "Триггеры и страхи",
                        "Зоны личного роста"]
            case .idealPartner:
                return ["Эмоциональные потребности",
                        "Подходящий темперамент",
                        "Важные границы",
                        "Портрет партнера"]
            case .loveLanguage:
                return ["Ваш язык любви",
                        "Способы проявления чувств",
                        "Эмоциональные потребности",
                        "Ошибки в коммуникации"]
        }
    }
}

enum CompatibilityTestType: String, TestCellDisplayable {
    case astrology = "Астрология пары"
    case behavioralPatterns = "Поведенческие паттерны"
    case attachmentCompatibility = "Стили привязанности"
    case loveLanguages = "Языки любви"
    case conflictResolution = "Конфликты и примирение"
    case sexualCompatibility = "Сексуальная совместимость"

    var title: String { rawValue }

    var description: String {
        switch self {
            case .astrology:
                return "Общая динамика"
            case .behavioralPatterns:
                return "Как вы ведете себя"
            case .attachmentCompatibility:
                return "Безопасность и дистанция"
            case .loveLanguages:
                return "Как вы даете и принимаете любовь"
            case .conflictResolution:
                return "Триггеры и ссоры"
            case .sexualCompatibility:
                return "Химия и интимные ожидания"
        }
    }

    var icon: String {
        switch self {
            case .astrology:
                return "sparkles"
            case .behavioralPatterns:
                return "person.2.wave.2"
            case .attachmentCompatibility:
                return "lock.heart"
            case .loveLanguages:
                return "heart"
            case .conflictResolution:
                return "bubble.left.and.bubble.right"
            case .sexualCompatibility:
                return "flame"
        }
    }

    var color: UIColor {
        switch self {
            case .astrology:
                return .systemIndigo
            case .behavioralPatterns:
                return .systemTeal
            case .attachmentCompatibility:
                return .systemOrange
            case .loveLanguages:
                return .systemRed
            case .conflictResolution:
                return .systemBlue
            case .sexualCompatibility:
                return .systemPink
        }
    }

    var deepDescription: String {
        switch self {
            case .astrology:
                return "Сравните ваши натальные показатели и узнайте, где между вами возникает легкость, напряжение, притяжение и долгосрочный потенциал."
            case .behavioralPatterns:
                return "Разберите, как ваши привычные реакции сочетаются в паре: кто сближается, кто отдаляется, где возникает поддержка, а где недопонимание."
            case .attachmentCompatibility:
                return "Поймите, насколько ваши стили привязанности подходят друг другу и какие сценарии могут создавать тревогу, холодность или ощущение безопасности."
            case .loveLanguages:
                return "Сравните ваши способы проявлять любовь, принимать заботу и чувствовать значимость в отношениях."
            case .conflictResolution:
                return "Узнайте, как вы оба ведете себя в конфликте, какие триггеры усиливают ссоры и какие способы примирения подходят вашей паре."
            case .sexualCompatibility:
                return "Исследуйте уровень интимной совместимости: желания, ожидания и скрытые несовпадения. Поймёте, где возникает напряжение и как усилить химию между вами."
        }
    }

    var includedItems: [String] {
        switch self {
            case .astrology:
                return ["Синастрия пары",
                        "Солнце, Луна и Венера",
                        "Точки притяжения",
                        "Потенциал отношений"]
            case .behavioralPatterns:
                return ["Реакции в близости",
                        "Поведение в стрессе",
                        "Роли в отношениях",
                        "Повторяющиеся сценарии"]
            case .attachmentCompatibility:
                return ["Стили привязанности",
                        "Потребность в дистанции",
                        "Тревожные триггеры",
                        "Чувство безопасности"]
            case .loveLanguages:
                return ["Языки любви пары",
                        "Способы заботы",
                        "Ожидания от партнера",
                        "Эмоциональная связь"]
            case .conflictResolution:
                return ["Типичные конфликты",
                        "Триггеры напряжения",
                        "Стратегии примирения",
                        "Зоны договоренностей"]
            case .sexualCompatibility:
                return ["Уровень влечения",
                        "Интимные ожидания",
                        "Совпадение желаний",
                        "Потенциал химии"]
        }
    }
}

#Preview {
    ForEach(TestType.allCases, id: \.self) { test in
        TestCellView(type: test, showSelection: false) {

        }
    }
    .padding(.horizontal)
}
