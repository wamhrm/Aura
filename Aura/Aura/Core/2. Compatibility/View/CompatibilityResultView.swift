//
//  CompatibilityResultView.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import SwiftUI

struct CompatibilityResultView: View {
    @Environment(\.locale) private var locale
    let result: CompatibilityResultModel

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 15) {
                    compatibilityScaleBar(result.compatibilityScore)
                        .padding(.vertical)

                    HStack(spacing: 75) {
                        VStack {
                            Text(result.userZodiacSign.icon)
                                .compatibilityResultZodiacsModifier()

                            Text(result.userNameCapitalized)
                                .font(Adaptive.size(.callout, .default, .default))
                                .bold()
                        }
                        .frame(width: Adaptive.size(150, 156, 164), alignment: .trailing)

                        VStack {
                            Text(result.partnerZodiacIcon)
                                .compatibilityResultZodiacsModifier()

                            Text(result.partnerNameCapitalized)
                                .font(Adaptive.size(.callout, .default, .default))
                                .bold()
                                .lineLimit(2)
                        }
                        .frame(width: Adaptive.size(150, 156, 164), alignment: .leading)
                    }
                    .font(.title3)
                    .overlay {
                        Image(systemName: "heart")
                            .font(Adaptive.size(.title3, .system(size: 21), .title2))
                            .foregroundStyle(.red)
                    }

                    VStack(spacing: Adaptive.size(12, 12, 13)) {
                        Text(result.title)
                            .font(Adaptive.size(.callout, .default, .default))
                            .foregroundStyle(.tint)
                            .bold()

                        Text(result.subtitle)
                            .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
                            .foregroundStyle(.deepGray)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: Adaptive.size(310, 315, 320))
                    .padding(.bottom, 10)

                    ResultSectionView(title: Text(verbatim: result.overview.title)) {
                        Text(result.overview.description)
                            .font(.system(size: Adaptive.size(14, 15, 15)))
                            .foregroundStyle(.deepGray)
                    }

                    ResultSectionView(title: Text("Эмоциональная совместимость")) {
                        VStack(spacing: 15) {
                            ForEach(result.emotionalBar, id: \.self) { bar in
                                EmotionalProfileBar(type: bar.key, value: bar.value)
                            }
                        }
                        .padding(.top, 5)
                    }

                    ForEach(result.sections, id: \.self) { section in
                        ResultSectionView(title: Text(section.selectedTest.title)) {
                            Text(section.description)
                                .font(.system(size: Adaptive.size(14, 15, 15)))
                                .foregroundStyle(.deepGray)

                            VStack(spacing: 12) {
                                ForEach(section.items.enumerated(), id: \.element) { index, item in
                                    TestResultCellView(test: item.key,
                                                       description: item.description)

                                    if index < section.items.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .testTopicsModifier()
                        }
                    }

                    ResultSectionView(title: Text("Прогноз будущего")) {
                        VStack(spacing: 12) {
                            resultsWithNumbersSection(.spark,
                                                      result.forecast.recognitionTitle,
                                                      result.forecast.recognitionDescription)

                            resultsWithNumbersSection(.potential,
                                                      result.forecast.potentialTitle,
                                                      result.forecast.potentialDescription)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .bottomAreaPadding(15)
            }
        }
        .localizedNavigationTitle("Результат теста на совместимость")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension CompatibilityResultView {
    private func compatibilityScaleBar(_ value: Int) -> some View {
        VStack(spacing: 12) {
            let fraction = Double(min(max(value, 0), 100)) / 100

            ZStack {
                Circle()
                    .stroke(.tint.opacity(0.18), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: CGFloat(fraction))
                    .stroke(.tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(fraction, format: .percent.precision(.fractionLength(0)).locale(locale))
                    .font(Adaptive.size(.title3, .system(size: 21), .system(size: 21)))
                    .bold()
                    .foregroundStyle(.tint)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(width: Adaptive.size(150, 158, 168),
                   height: Adaptive.size(150, 158, 168))

            VStack(spacing: 2) {
                Text("Совместимость солнечных знаков")
                Text("Не зависит от выбранных разделов")
            }
            .font(Adaptive.size(.caption2, .caption, .caption))
            .foregroundStyle(Color.deepGray)
            .multilineTextAlignment(.center)
        }
    }

    private func resultsWithNumbersSection(_ type: LoveLanguageTypes,
                                           _ title: String,
                                           _ description: String) -> some View {
        HStack(alignment: .top) {
            Text(type.number)
                .font(Adaptive.size(.callout, .default, .default))
                .fontWeight(.semibold)
                .foregroundStyle(numberStyle(type: type))
                .padding(10)
                .background(numberStyle(type: type).opacity(0.15))
                .clipShape(.circle)
                .frame(width: Adaptive.size(35, 37, 38), alignment: .leading)

            VStack(alignment: .leading, spacing: 7) {
                Text(type.title)
                    .textCase(.uppercase)
                    .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)

                Text(title)
                    .font(.system(size: Adaptive.size(14, 15, 15)))
                    .bold()

                Text(description)
                    .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
                    .foregroundStyle(.deepGray)
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func numberStyle(type: LoveLanguageTypes) -> AnyShapeStyle {
        switch type {
            case .spark: AnyShapeStyle(.tint)
            case .potential: AnyShapeStyle(.yellow)
        }
    }
}

fileprivate enum LoveLanguageTypes {
    case spark, potential

    var title: LocalizedStringResource {
        switch self {
            case .spark: "Искра"
            case .potential: "Потенциал"
        }
    }

    var number: String {
        switch self {
            case .spark: "1"
            case .potential: "2"
        }
    }
}

#Preview {
    NavigationStack {
        CompatibilityResultView(result: .mock)
    }
}
