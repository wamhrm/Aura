//
//  CompatibilityResultView.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import SwiftUI

struct CompatibilityResultView: View {
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
                                .font(Adaptive.size(.callout, .default))
                                .bold()
                        }
                        .frame(width: 150, alignment: .trailing)

                        VStack {
                            Text(result.partnerZodiacSignHandler)
                                .compatibilityResultZodiacsModifier()

                            Text(result.partnerNameCapitalized)
                                .font(Adaptive.size(.callout, .default))
                                .bold()
                                .lineLimit(2)
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
                            .foregroundStyle(.tint)
                            .bold()

                        Text(result.subtitle)
                            .font(Adaptive.size(.footnote, .system(size: 15)))
                            .foregroundStyle(.deepGray)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: Adaptive.size(310, 320))
                    .padding(.bottom, 10)

                    ResultSectionView(title: result.overview.title) {
                        Text(result.overview.description)
                            .font(.system(size: Adaptive.size(14, 15)))
                            .foregroundStyle(.deepGray)
                    }

                    ResultSectionView(title: "Эмоциональная совместимость") {
                        VStack(spacing: 15) {
                            ForEach(result.emotionalBar, id: \.self) { bar in
                                EmotionalProfileBar(type: bar.key, value: bar.value)
                            }
                        }
                        .padding(.top, 5)
                    }

                    ForEach(result.sections, id: \.self) { section in
                        ResultSectionView(title: section.selectedTest.title) {
                            Text(section.description)
                                .font(.system(size: Adaptive.size(14, 15)))
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

                    ResultSectionView(title: "Прогноз будущего") {
                        VStack(spacing: 12) {
                            resultsWithNumbersSection(.spark,
                                                      result.forecast.recognitionTitle,
                                                      result.forecast.recognitionDescription)

                            resultsWithNumbersSection(.potential,
                                                      result.forecast.potentialTitle,
                                                      result.forecast.potentialDescription)
                        }
                    }

                    AIResultDisclaimerView()
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
                .stroke(.tint.opacity(0.18), lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(min(max(value, 0), 100)) / 100)
                .stroke(.tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 5) {
                Text("\(min(max(value, 0), 100))%")
                    .font(Adaptive.size(.title3, .system(size: 21)))
                    .bold()
                    .foregroundStyle(.tint)
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

    private func resultsWithNumbersSection(_ type: LoveLanguageTypes,
                                           _ title: String,
                                           _ description: String) -> some View {
        HStack(alignment: .top) {
            Text(type.number)
                .font(Adaptive.size(.callout, .default))
                .fontWeight(.semibold)
                .foregroundStyle(numberStyle(for: type))
                .padding(10)
                .background(numberStyle(for: type).opacity(0.15))
                .clipShape(.circle)
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

    private func numberStyle(for type: LoveLanguageTypes) -> AnyShapeStyle {
        switch type {
            case .spark: AnyShapeStyle(.tint)
            case .potential: AnyShapeStyle(.yellow)
        }
    }
}

fileprivate enum LoveLanguageTypes: String {
    case spark = "Искра"
    case potential = "Потенциал"

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
