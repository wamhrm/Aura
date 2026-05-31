//
//  Components.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
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
            .clipShape(Circle())
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
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
            .background(RoundedRectangle(cornerRadius: isResults ? 8 : 15).fill(Color(color).opacity(0.2)))
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
                .clipShape(Circle())
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

struct ServerWakingUpView: View {
    let isVisible: Bool

    var body: some View {
        VStack(spacing: 30) {
            ProgressView()

            VStack(spacing: 20) {
                Text("Сервер просыпается. Первый запуск может занять до 50 секунд.")
                    .lineSpacing(3)

                Text("Пожалуйста, ожидайте.")
            }
            .font(.callout)
            .bold()
            .multilineTextAlignment(.center)
            .padding(.horizontal, 55)
        }
        .animation(.easeInOut(duration: 0.25), value: isVisible)
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
