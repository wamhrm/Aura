//
//  Components.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import Foundation
import SwiftUI

struct BackgroundView: View {
    var body: some View {
        Color(uiColor: .appBackground).ignoresSafeArea()
    }
}

struct HoroscopeDateView: View {
    let dateStart: String
    let dateEnd: String
    let isCellDetails: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(dateStart)

            Rectangle()
                .frame(width: isCellDetails ? 10 : 6, height: 1)

            Text(dateEnd)
        }
        .font(Adaptive.size(.caption, .footnote))
        .fontWeight(isCellDetails ? .bold : .medium)
        .foregroundStyle(.deepGray)
    }
}

struct LogoImage: View {
    let size: CGFloat

    var body: some View {
        Image("logo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(.circle)
            .clipped()
    }
}

struct ClassicButton: View {
    let title: String
    let action: () -> Void
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Adaptive.size(14, 15)))
                .foregroundStyle(.white)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(AccentColorOption.color(accentColor))
                .clipShape(.rect(cornerRadius: 10))
        }
    }
}

struct TestCellImage: View {
    let icon: String
    let color: UIColor
    let iconSize: Font
    let backgroundSize: CGFloat
    let isResults: Bool

    var body: some View {
        Image(systemName: icon)
            .font(iconSize)
            .foregroundStyle(Color(color))
            .padding(10)
            .frame(width: backgroundSize, height: backgroundSize)
            .background(Color(color).opacity(0.2), in: .rect(cornerRadius: isResults ? 8 : 15))
    }
}

struct CompleteProfileLock: View {
    let title: String

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "lock")
                .imageScale(.large)
                .fontWeight(.semibold)
                .foregroundStyle(.deepGray)
                .padding()
                .background(Color.fieldBackground.opacity(0.75))
                .clipShape(.circle)
                .overlay(Circle().stroke(Color.fieldBorder, lineWidth: 1))

            Text(title)
                .font(Adaptive.size(.system(size: 15), .callout))
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct AIConsentLock: View {
    let title: String
    let onAllow: () -> Void
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        VStack(spacing: 0) {
            CompleteProfileLock(title: title)

            Button(action: onAllow) {
                Text("Разрешить")
                    .font(Adaptive.size(.system(size: 15), .callout))
                    .fontWeight(.semibold)
                    .foregroundStyle(AccentColorOption.color(accentColor))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 11)
                    .background(.white)
                    .clipShape(.capsule)
                    .overlay(Capsule().stroke(Color.fieldBorder, lineWidth: 1))
            }
        }
    }
}

struct EmotionalProfileBar: View {
    let type: EmotionalProfileTypes
    let value: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(type.leftSide)

                Spacer()

                Text(type.rightSide)
            }
            .font(Adaptive.size(.caption, .system(size: 14)))
            .fontWeight(.semibold)
            .foregroundStyle(.deepGray)

            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.fieldBackground)

                    Capsule()
                        .fill(LinearGradient(colors: type.colors,
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: bar.size.width * (CGFloat(value) / CGFloat(10)))
                }
            }
            .frame(height: Adaptive.size(8, 10))
        }
    }
}

enum EmotionalProfileTypes: String, Codable {
    case temperament = "Темперамент"
    case thinking = "Мышление"
    case organization = "Организованность"
    case relationships = "Отношения"
    case emotionalResonance = "Эмоциональный резонанс"
    case innerOpenness = "Внутренняя открытость"
    case soulAlignment = "Гармония души"
    case emotionalWarmth = "Эмоциональная теплота"

    var leftSide: String {
        switch self {
            case .temperament: "Интроверсия"
            case .thinking: "Логика"
            case .organization: "Хаос"
            case .relationships: "Независимость"
            case .emotionalResonance: "Дистанция"
            case .innerOpenness: "Закрытость"
            case .soulAlignment: "Недопонимание"
            case .emotionalWarmth: "Холодная дистанция"
        }
    }

    var rightSide: String {
        switch self {
            case .temperament: "Экстраверсия"
            case .thinking: "Интуиция"
            case .organization: "Контроль"
            case .relationships: "Привязанность"
            case .emotionalResonance: "Близость"
            case .innerOpenness: "Душевная открытость"
            case .soulAlignment: "Взаимопонимание"
            case .emotionalWarmth: "Теплая привязанность"
        }
    }

    var colors: [Color] {
        switch self {
            case .temperament, .thinking, .organization, .relationships:
                [.purple, .softPurple]
            case .emotionalResonance, .innerOpenness, .soulAlignment, .emotionalWarmth:
                [.blue, .softPurple]
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LogoImage(size: 50)

        HoroscopeDateView(dateStart: "27 окт.", dateEnd: "2 нояб.", isCellDetails: true)

        TestCellImage(icon: "sparkles", color: .systemPurple, iconSize: .title3, backgroundSize: 50, isResults: false)

        EmotionalProfileBar(type: .temperament, value: 7)

        CompleteProfileLock(title: "Пройдите тесты для получения результатов о себе")

        AIConsentLock(title: "Разрешите анализ с помощью AI") {

        }

        ClassicButton(title: "Готово") {

        }
    }
    .padding(.horizontal)
}
