//
//  Components.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import SwiftUI

struct Components {
    static func backgroundColor() -> some View {
        return Color(uiColor: .appBackground).ignoresSafeArea()
    }

    static func horoscopeDate(_ dateStart: String, _ dateEnd: String, _ isCellDetails: Bool) -> some View {
        HStack(spacing: 4) {
            Text(dateStart)

            Rectangle()
                .frame(width: isCellDetails ? 10 : 6, height: 1)

            Text(dateEnd)
        }
        .font(.caption)
        .fontWeight(isCellDetails ? .bold : .medium)
        .foregroundStyle(.deepGray)
    }

    static func logoImage(_ size: CGFloat) -> some View {
        Image("logo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .clipped()
    }

    static func classicButton(_ title: String, _ completion: @escaping () -> Void) -> some View {
        Button {
            completion()
        } label: {
            Text(title)
                .font(Components.isRegular(.system(size: 14), .system(size: 16)))
                .foregroundStyle(.white)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(LinearGradient(colors: [.blue, .blue.opacity(0.65)],
                                           startPoint: .leading,
                                           endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    static func testCellImage(_ title: String, _ color: UIColor, _ imgSize: Font, _ backgroundSize: CGFloat, _ isResults: Bool) -> some View {
        Image(systemName: title)
            .font(imgSize)
            .foregroundStyle(Color(color))
            .padding(10)
            .frame(width: backgroundSize, height: backgroundSize)
            .background(RoundedRectangle(cornerRadius: isResults ? 8 : 15) .fill(Color(color).opacity(0.2)))
    }

    static func completeYourProfileLock(_ title: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "lock")
                .imageScale(.large)
                .fontWeight(.semibold)
                .foregroundStyle(.deepGray)
                .padding()
                .background(Color(.systemGray6).opacity(0.75))
                .clipShape(Circle())
                .overlay(Circle() .stroke(Color(.systemGray5), lineWidth: 1))

            Text(title)
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    static func emotionalProfileBar(_ type: EmotionalProfileTypes, _ value: Int) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(type.leftSide)

                Spacer()

                Text(type.rightSide)
            }
            .font(Components.isRegular(.system(size: 12), .system(size: 14)))
            .fontWeight(.semibold)
            .foregroundStyle(.deepGray)

            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray6))

                    Capsule()
                        .fill(LinearGradient(colors: type.colors,
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: bar.size.width * (CGFloat(value) / CGFloat(10)))
                }
            }
            .frame(height: Components.isRegular(8, 10))
        }
    }
    
    static func isServerWakingUpView(_ value: Bool) -> some View {
        VStack(spacing: 30) {
            ProgressView()
            
            VStack(spacing: 20) {
                Text("Сервер просыпается. Первый запуск может занять до 40 секунд.")
                    .lineSpacing(3)

                Text("Пожалуйста, ожидайте.")
            }
            .font(.callout)
            .bold()
            .multilineTextAlignment(.center)
            .padding(.horizontal, 55)
        }
        .animation(.easeInOut(duration: 0.25), value: value)
    }

    static func isRegular<T>(_ regular: T, _ proMax: T) -> T {
        return UIDevice.isProMax ? proMax : regular
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
            case .temperament:
                return "Интроверсия"
            case .thinking:
                return "Логика"
            case .organization:
                return "Хаос"
            case .relationships:
                return "Независимость"
            case .emotionalResonance:
                return "Дистанция"
            case .innerOpenness:
                return "Закрытость"
            case .soulAlignment:
                return "Недопонимание"
            case .emotionalWarmth:
                return "Холодная дистанция"
            }
    }

    var rightSide: String {
        switch self {
            case .temperament:
                return "Экстраверсия"
            case .thinking:
                return "Интуиция"
            case .organization:
                return "Контроль"
            case .relationships:
                return "Привязанность"
            case .emotionalResonance:
                return "Близость"
            case .innerOpenness:
                return "Душевная открытость"
            case .soulAlignment:
                return "Взаимопонимание"
            case .emotionalWarmth:
                return "Теплая привязанность"
        }
    }

    var colors: [Color] {
        switch self {
            case .temperament, .thinking, .organization, .relationships:
                return [.purple, .softPurple]
            case .emotionalResonance, .innerOpenness, .soulAlignment, .emotionalWarmth:
                return [.blue, .softPurple]
        }
    }
}
