//
//  Components.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

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
        .font(Adaptive.size(.caption, .footnote, .footnote))
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
    }
}

struct ClassicButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Adaptive.size(14, 15, 15)))
                .foregroundStyle(.white)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(Adaptive.size(16, 16, 18))
                .background(.tint)
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
    let title: LocalizedStringResource

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
                .font(Adaptive.size(.system(size: 15), .callout, .callout))
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct AIConsentLock: View {
    let title: LocalizedStringResource
    let onAllow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CompleteProfileLock(title: title)

            Button(action: onAllow) {
                Text("Разрешить")
                    .font(Adaptive.size(.system(size: 15), .callout, .callout))
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 11)
                    .background(.white)
                    .clipShape(.capsule)
                    .overlay(Capsule().stroke(Color.fieldBorder, lineWidth: 1))
            }
        }
    }
}

struct AIConsentContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .center, spacing: 25) {
                    Image(systemName: "sparkles")
                        .font(Adaptive.size(.title2, .system(size: 24), .title))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(15)
                        .background(LinearGradient(colors: [.purple, .softPurple],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing))
                        .clipShape(.circle)

                    Text("Анализ с помощью AI")
                        .font(Adaptive.size(.default, .system(size: 18), .title3))
                        .bold()
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 25) {
                    Text("Инсайт и совет дня, тесты личности и совместимости составляет сервис искусственного интеллекта OpenAI (США). Для этого Aura передаёт ему:")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• ваше имя, дату рождения, знак зодиака, пол, ответы анкеты и время рождения, если оно указано;")
                        Text("• для контента дня — текущую дату, для тестов — выбранные темы;")
                        Text("• для теста совместимости — имя, дату рождения и знак зодиака партнёра, время рождения (если указано) и рассчитанный по знакам процент совместимости.")
                    }

                    Text("Адрес почты не передаётся. Гороскоп работает и без этого разрешения.")

                    if let url = Constants.privacyPolicyURL {
                        Link("Политика конфиденциальности", destination: url)
                            .fontWeight(.semibold)
                    }
                }
            }
            .font(Adaptive.size(.system(size: 14), .system(size: 15), .callout))
            .padding(.top)
            .onboardingViewModifier()
        }
        .scrollIndicators(.hidden)
    }
}

struct BirthDateFieldsView: View {
    @Binding var birthDate: Date
    @Binding var knowsBirthTime: Bool
    @Binding var birthTime: Date
    let dateRange: ClosedRange<Date>

    var body: some View {
        VStack(spacing: 12) {
            DatePicker("Дата рождения",
                       selection: $birthDate,
                       in: dateRange,
                       displayedComponents: .date)

            Toggle("Я знаю время рождения", isOn: $knowsBirthTime.animation())

            if knowsBirthTime {
                DatePicker("Время",
                           selection: $birthTime,
                           displayedComponents: .hourAndMinute)
            }
        }
        .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
        .fontWeight(.medium)
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
            .font(Adaptive.size(.caption, .footnote, .system(size: 14)))
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
            .frame(height: Adaptive.size(8, 8, 10))
        }
    }
}

struct LoadFailedView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(message)
                .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

            Button("Повторить", action: onRetry)
                .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

enum EmotionalProfileTypes: String, Codable {
    case temperament, thinking, organization, relationships, emotionalResonance, innerOpenness, soulAlignment, emotionalWarmth

    fileprivate var leftSide: LocalizedStringResource {
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

    fileprivate var rightSide: LocalizedStringResource {
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

    fileprivate var colors: [Color] {
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

        HoroscopeDateView(dateStart: AppLanguage.text("27 окт."), dateEnd: AppLanguage.text("2 нояб."), isCellDetails: true)

        TestCellImage(icon: "sparkles", color: .systemPurple, iconSize: .title3, backgroundSize: 50, isResults: false)

        EmotionalProfileBar(type: .temperament, value: 7)

        CompleteProfileLock(title: "Пройдите тесты для получения результатов о себе")

        LoadFailedView(message: AppLanguage.text("Сервис временно недоступен. Попробуйте позже")) {

        }

        AIConsentLock(title: "Разрешите анализ с помощью AI") {

        }

        ClassicButton(title: "Готово") {

        }
    }
    .padding(.horizontal)
}
