//
//  CompatibilityResultView.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import SwiftUI

struct CompatibilityResultView: View {
    let result: CompabilityResultModel

    var body: some View {
        ZStack {
            Components.backgroundColor()

            ScrollView {
                VStack(spacing: 15) {
                    compatibilityScaleBar(result.compatibilityScore)
                        .padding(.vertical)

                    HStack(spacing: 75) {
                        VStack {
                            Text(result.userZodiacSign)
                                .padding(10)
                                .background(.deepBlue.opacity(0.25))
                                .clipShape(Circle())

                            Text(result.userName)
                                .bold()
                        }
                        .frame(width: 150, alignment: .trailing)

                        VStack {
                            Text(result.partnerZodiacSign)
                                .padding(10)
                                .background(.purple.opacity(0.25))
                                .clipShape(Circle())

                            Text(result.partnerName)
                                .bold()
                        }
                        .frame(width: 150, alignment: .leading)
                    }
                    .font(.title3)
                    .overlay {
                        Image(systemName: "heart")
                            .font(.title3)
                            .foregroundStyle(.red)
                    }

                    VStack(spacing: 10) {
                        Text(result.title)
                            .foregroundStyle(.deepBlue)
                            .bold()

                        Text(result.subtitle)
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
                    .padding(.bottom, 10)

                    Components.resultsSection(result.overview.title) {
                        Text(result.overview.description)
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                    }

                    Components.resultsSection("Эмоциональная совместимость") {
                        VStack(spacing: 15) {
                            ForEach(result.emotionalBar, id: \.self) { bar in
                                Components.emotionalProfileBar(bar.title, bar.value)
                            }
                        }
                        .padding(.top, 5)
                    }

                    ForEach(result.sections, id: \.self) { section in
                        Components.resultsSection(section.selectedTest.rawValue) {
                            Text(section.description)
                                .font(.callout)
                                .foregroundStyle(.deepGray)

                            VStack(spacing: 12) {
                                ForEach(Array(section.items.enumerated()), id: \.element) { index, item in
                                    TestResultCellView(test: item.title, description: item.description)

                                    if index < section.items.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .testTopicsModifier()
                        }
                    }

                    Components.resultsSection("Прогноз будущего") {
                        VStack(spacing: 12) {
                            Components.resultsWithNumbersSection(
                                .spark,
                                result.forecast.recognitionTitle,
                                result.forecast.recognitionDescription
                            )

                            Components.resultsWithNumbersSection(
                                .potentional,
                                result.forecast.potentialTitle,
                                result.forecast.potentialDescription
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Результат теста на совместимость")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
    }
}

extension CompatibilityResultView {
    private func compatibilityScaleBar(_ value: Int) -> some View {
        ZStack {
            Circle()
                .stroke(Color.deepBlue.opacity(0.18), lineWidth: 10)

            Circle()
                .trim(from: 0, to: CGFloat(min(max(value, 0), 100)) / 100)
                .stroke(Color.deepBlue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 5) {
                Text("\(min(max(value, 0), 100))%")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.deepBlue)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("СОВМЕСТИМОСТЬ")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.deepGray)
            }
        }
        .frame(width: 150, height: 150)
    }
}

#Preview {
    NavigationStack {
        CompatibilityResultView(result: .mock)
    }
}
