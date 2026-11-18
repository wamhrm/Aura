//
//  TestCellView.swift
//  Aura
//
//  Created by wamhrm on 04.05.2026.
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
    let hasChosenTest: Bool
    let onSelectionToggle: () -> Void
    let onTapHandler: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            Button(action: onTapHandler) {
                HStack(spacing: 15) {
                    TestCellImage(icon: type.icon, color: type.color, iconSize: .title2, backgroundSize: Adaptive.size(43, 43, 45), isResults: false)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(type.title)
                            .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)

                        Text(type.description)
                            .font(Adaptive.size(.caption, .footnote, .footnote))
                            .fontWeight(.medium)
                            .foregroundStyle(.deepGray)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onSelectionToggle) {
                Circle()
                    .fill(.tint.opacity(hasChosenTest ? 0.85 : 0))
                    .frame(width: Adaptive.size(23, 23, 25),
                           height: Adaptive.size(23, 23, 25))
                    .overlay(Circle().stroke(Color.fieldBackground, lineWidth: 2))
                    .overlay {
                        Circle()
                            .fill(.cardBackground)
                            .frame(width: Adaptive.size(8, 8, 10),
                                   height: Adaptive.size(8, 8, 10))
                    }
                    .padding(.trailing, 5)
            }
            .accessibilityLabel(hasChosenTest
                                ? AppLanguage.text("Убрать \(type.title)")
                                : AppLanguage.text("Выбрать \(type.title)"))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(12, .cardBackground, showsStroke: true)
        .foregroundStyle(.primaryText)
    }
}

enum PersonalityTestTypes: String, TestCellDisplayable, Codable {
    case astrology, behavioralPatterns, decisionMaking, attachmentStyle, idealPartner, loveLanguage

    var title: String {
        switch self {
            case .astrology: AppLanguage.text("Астрологический портрет")
            case .behavioralPatterns: AppLanguage.text("Поведенческие паттерны")
            case .decisionMaking: AppLanguage.text("Стиль принятия решений")
            case .attachmentStyle: AppLanguage.text("Стиль привязанности")
            case .idealPartner: AppLanguage.text("Идеальный партнер")
            case .loveLanguage: AppLanguage.text("Язык любви")
        }
    }

    var description: String {
        switch self {
            case .astrology: AppLanguage.text("Что говорит ваш знак")
            case .behavioralPatterns: AppLanguage.text("Разберите свои реакции")
            case .decisionMaking: AppLanguage.text("Поймите, как вы выбираете")
            case .attachmentStyle: AppLanguage.text("Определите ваш стиль отношений")
            case .idealPartner: AppLanguage.text("Соберите портрет партнера")
            case .loveLanguage: AppLanguage.text("Как вы выражаете любовь?")
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
            case .astrology: AppLanguage.text("Получите разбор по вашему знаку зодиака: сильные стороны личности, внутренние конфликты и природные склонности. Поймёте, что влияет на ваши решения и поведение.")
            case .behavioralPatterns: AppLanguage.text("Разберите повторяющиеся сценарии поведения: как вы реагируете на стресс, близость, неопределенность и эмоциональное напряжение.")
            case .decisionMaking: AppLanguage.text("Поймите, что сильнее влияет на ваши решения: эмоции, логика, интуиция или потребность в стабильности. Это поможет выбирать спокойнее и увереннее.")
            case .attachmentStyle: AppLanguage.text("Определите свой стиль привязанности и разберите модели поведения в отношениях. Узнаете, почему вы реагируете определённым образом и какие сценарии повторяются чаще всего.")
            case .idealPartner: AppLanguage.text("Соберите понятный портрет партнера, который подходит вашему темпераменту, эмоциональным потребностям и ожиданиям от близости.")
            case .loveLanguage: AppLanguage.text("Поймите, как вы выражаете любовь и что делает вас эмоционально удовлетворённым в отношениях. Это поможет лучше понимать себя и избегать типичных недопониманий.")
        }
    }

    var includedItems: [String] {
        switch self {
            case .astrology: [AppLanguage.text("Черты вашего знака"),
                        AppLanguage.text("Знак и ваш характер"),
                        AppLanguage.text("Сильные и слабые стороны"),
                        AppLanguage.text("Личностные особенности")]
            case .behavioralPatterns: [AppLanguage.text("Повторяющиеся реакции"),
                        AppLanguage.text("Поведение в стрессе"),
                        AppLanguage.text("Социальные сценарии"),
                        AppLanguage.text("Зоны личного роста")]
            case .decisionMaking: [AppLanguage.text("Стиль выбора"),
                        AppLanguage.text("Роль эмоций и логики"),
                        AppLanguage.text("Реакция на неопределенность"),
                        AppLanguage.text("Риски импульсивности")]
            case .attachmentStyle: [AppLanguage.text("Тип привязанности"),
                        AppLanguage.text("Поведение в отношениях"),
                        AppLanguage.text("Триггеры и страхи"),
                        AppLanguage.text("Зоны личного роста")]
            case .idealPartner: [AppLanguage.text("Эмоциональные потребности"),
                        AppLanguage.text("Подходящий темперамент"),
                        AppLanguage.text("Важные границы"),
                        AppLanguage.text("Портрет партнера")]
            case .loveLanguage: [AppLanguage.text("Ваш язык любви"),
                        AppLanguage.text("Способы проявления чувств"),
                        AppLanguage.text("Эмоциональные потребности"),
                        AppLanguage.text("Ошибки в коммуникации")]
        }
    }
}

enum CompatibilityTestTypes: String, TestCellDisplayable, Codable {
    case astrology, behavioralPatterns, attachmentCompatibility, loveLanguages, conflictResolution, sexualCompatibility

    var title: String {
        switch self {
            case .astrology: AppLanguage.text("Астрология пары")
            case .behavioralPatterns: AppLanguage.text("Поведенческие паттерны")
            case .attachmentCompatibility: AppLanguage.text("Стили привязанности")
            case .loveLanguages: AppLanguage.text("Языки любви")
            case .conflictResolution: AppLanguage.text("Конфликты и примирение")
            case .sexualCompatibility: AppLanguage.text("Сексуальная совместимость")
        }
    }

    var description: String {
        switch self {
            case .astrology: AppLanguage.text("Сочетание солнечных знаков, точки гармонии и возможные противоречия")
            case .behavioralPatterns: AppLanguage.text("Ваши особенности поведения и возможные сценарии взаимодействия")
            case .attachmentCompatibility: AppLanguage.text("Возможные сценарии близости, доверия и личных границ")
            case .loveLanguages: AppLanguage.text("Способы выражения заботы и возможные различия в ожиданиях")
            case .conflictResolution: AppLanguage.text("Ваш подход к разногласиям и возможные пути примирения")
            case .sexualCompatibility: AppLanguage.text("Возможная динамика влечения и близости")
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
            case .astrology: AppLanguage.text("Сочетание солнечных знаков, точки гармонии и возможные противоречия. Это не натальная карта и не расчёт планет.")
            case .behavioralPatterns: AppLanguage.text("Ваши особенности поведения и возможные сценарии взаимодействия. Привычки партнёра по этим данным неизвестны.")
            case .attachmentCompatibility: AppLanguage.text("Возможные сценарии близости, доверия и личных границ. Стиль привязанности партнёра по этим данным не определяется.")
            case .loveLanguages: AppLanguage.text("Способы выражения заботы и возможные различия в ожиданиях. Язык любви партнёра по этим данным неизвестен.")
            case .conflictResolution: AppLanguage.text("Ваш подход к разногласиям и возможные пути примирения. Реакции партнёра в ссоре по этим данным неизвестны.")
            case .sexualCompatibility: AppLanguage.text("Возможная динамика влечения, темпа сближения и интимной гармонии.")
        }
    }

    var includedItems: [String] {
        switch self {
            case .astrology: [AppLanguage.text("Совместимость знаков"),
                        AppLanguage.text("Сильные и слабые стороны пары"),
                        AppLanguage.text("Точки притяжения"),
                        AppLanguage.text("Потенциал отношений")]
            case .behavioralPatterns: [AppLanguage.text("Реакции в близости"),
                        AppLanguage.text("Поведение в стрессе"),
                        AppLanguage.text("Роли в отношениях"),
                        AppLanguage.text("Повторяющиеся сценарии")]
            case .attachmentCompatibility: [AppLanguage.text("Стили привязанности"),
                        AppLanguage.text("Потребность в дистанции"),
                        AppLanguage.text("Тревожные триггеры"),
                        AppLanguage.text("Чувство безопасности")]
            case .loveLanguages: [AppLanguage.text("Языки любви пары"),
                        AppLanguage.text("Способы заботы"),
                        AppLanguage.text("Ожидания от партнера"),
                        AppLanguage.text("Эмоциональная связь")]
            case .conflictResolution: [AppLanguage.text("Типичные конфликты"),
                        AppLanguage.text("Триггеры напряжения"),
                        AppLanguage.text("Стратегии примирения"),
                        AppLanguage.text("Зоны договоренностей")]
            case .sexualCompatibility: [AppLanguage.text("Сексуальный темперамент"),
                        AppLanguage.text("Сексуальная химия"),
                        AppLanguage.text("Темп сближения"),
                        AppLanguage.text("Возможные различия")]
        }
    }
}

#Preview {
    TestCellView(type: CompatibilityTestTypes.astrology, hasChosenTest: false) {

    } onTapHandler: {

    }
    .padding(.horizontal)
}
