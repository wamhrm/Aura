//
//  CompatibilityResultView.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import SwiftUI

struct CompatibilityResultView: View {
    let result: CompabilityResultModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 15) {
                    compatibilityScaleBar(result.compatibilityScore)
                        .padding(.vertical)

                    HStack(spacing: 75) {
                        VStack {
                            Text(result.userZodiacSign)
                                .compatibilityResultZodiacsModifier()

                            Text(result.userNameCapitalized)
                                .font(Adaptive.size(.callout, .default))
                                .bold()
                        }
                        .frame(width: 150, alignment: .trailing)

                        VStack {
                            Text(!result.partnerZodiacSign.isEmpty ? result.partnerZodiacSign : "👤")
                                .compatibilityResultZodiacsModifier()

                            Text(result.partnerNameCapitalized)
                                .font(Adaptive.size(.callout, .default))
                                .bold()
                        }
                        .frame(width: 150, alignment: .leading)
                    }
                    .font(.title3)
                    .overlay {
                        Image(systemName: "heart")
                            .font(Adaptive.size(.title3, .title2))
                            .foregroundStyle(.red)
                    }

                    VStack(spacing: Adaptive.size(12, 13)) {
                        Text(result.title)
                            .font(Adaptive.size(.callout, .default))
                            .foregroundStyle(AccentColorOption.color(accentColor))
                            .bold()

                        Text(result.subtitle)
                            .font(Adaptive.size(.footnote, .system(size: 15)))
                            .foregroundStyle(.deepGray)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: Adaptive.size(310, 320))
                    .padding(.bottom, 10)

                    resultsSection(result.overview.title) {
                        Text(result.overview.description)
                            .font(.system(size: Adaptive.size(14, 15)))
                            .foregroundStyle(.deepGray)
                    }

                    resultsSection("Эмоциональная совместимость") {
                        VStack(spacing: 15) {
                            ForEach(result.emotionalBar, id: \.self) { bar in
                                EmotionalProfileBar(type: bar.title, value: bar.value)
                            }
                        }
                        .padding(.top, 5)
                    }

                    ForEach(result.sections, id: \.self) { section in
                        resultsSection(section.selectedTest.rawValue) {
                            Text(section.description)
                                .font(.system(size: Adaptive.size(14, 15)))
                                .foregroundStyle(.deepGray)

                            VStack(spacing: 12) {
                                ForEach(Array(section.items.enumerated()), id: \.element) { index, item in
                                    TestResultCellView(test: item.title,
                                                       description: item.description)

                                    if index < section.items.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .testTopicsModifier()
                        }
                    }

                    resultsSection("Прогноз будущего") {
                        VStack(spacing: 12) {
                            resultsWithNumbersSection(.spark,
                                                      result.forecast.recognitionTitle,
                                                      result.forecast.recognitionDescription)

                            resultsWithNumbersSection(.potentional,
                                                      result.forecast.potentialTitle,
                                                      result.forecast.potentialDescription)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .bottomAreaPadding(15)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Результат теста на совместимость")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension CompatibilityResultView {
    private func compatibilityScaleBar(_ value: Int) -> some View {
        ZStack {
            Circle()
                .stroke(AccentColorOption.color(accentColor).opacity(0.18), lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(min(max(value, 0), 100)) / 100)
                .stroke(AccentColorOption.color(accentColor), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 5) {
                Text("\(min(max(value, 0), 100))%")
                    .font(Adaptive.size(.title3, .system(size: 21)))
                    .bold()
                    .foregroundStyle(AccentColorOption.color(accentColor))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("СОВМЕСТИМОСТЬ")
                    .font(Adaptive.size(.caption2, .caption))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.deepGray)
            }
        }
        .frame(width: 150, height: 150)
    }

    private func resultsSection<Content: View>(_ title: String,
                                               @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Adaptive.size(.system(size: 15), .default))
                .bold()

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(12, .cardBackground, true)
    }
    
    private func resultsWithNumbersSection(_ type: LoveLanguageTypes,
                                           _ title: String,
                                           _ description: String) -> some View {
        HStack(alignment: .top) {
            Text(type.number)
                .font(Adaptive.size(.callout, .default))
                .fontWeight(.semibold)
                .foregroundStyle(numberColor(for: type))
                .padding(10)
                .background(numberColor(for: type).opacity(0.15))
                .clipShape(Circle())
                .frame(width: 35, alignment: .leading)

            VStack(alignment: .leading, spacing: 7) {
                Text(type.rawValue.uppercased())
                    .font(Adaptive.size(.footnote, .system(size: 14)))
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)

                Text(title)
                    .font(.system(size: Adaptive.size(14, 15)))
                    .bold()

                Text(description)
                    .font(Adaptive.size(.footnote, .system(size: 14)))
                    .foregroundStyle(.deepGray)
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func numberColor(for type: LoveLanguageTypes) -> Color {
        switch type {
            case .main: .red
            case .additional, .spark: AccentColorOption.color(accentColor)
            case .potentional: .yellow
        }
    }
}

fileprivate enum LoveLanguageTypes: String {
    case main = "Основной"
    case additional = "Дополнительный"
    case spark = "Искра"
    case potentional = "Потенциал"

    var number: String {
        switch self {
            case .main, .spark: "1"
            case .additional, .potentional: "2"
        }
    }
}

#Preview {
    NavigationStack {
        CompatibilityResultView(result: .mock)
    }
}
