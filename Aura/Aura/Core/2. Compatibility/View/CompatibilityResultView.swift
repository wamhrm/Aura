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
                                .compatibilityResultZodiacsModifier()

                            Text(result.userNameCapitalized)
                                .font(Components.isRegular(.callout, .default))
                                .bold()
                        }
                        .frame(width: 150, alignment: .trailing)

                        VStack {
                            Text(result.partnerZodiacSign)
                                .compatibilityResultZodiacsModifier()

                            Text(result.partnerNameCapitalized)
                                .font(Components.isRegular(.callout, .default))
                                .bold()
                        }
                        .frame(width: 150, alignment: .leading)
                    }
                    .font(.title3)
                    .overlay {
                        Image(systemName: "heart")
                            .font(Components.isRegular(.title3, .title2))
                            .foregroundStyle(.red)
                    }

                    VStack(spacing: 12) {
                        Text(result.title)
                            .font(Components.isRegular(.callout, .default))
                            .foregroundStyle(.deepBlue)
                            .bold()

                        Text(result.subtitle)
                            .font(Components.isRegular(.footnote, .callout))
                            .foregroundStyle(.deepGray)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: 310)
                    .padding(.bottom, 10)

                    resultsSection(result.overview.title) {
                        Text(result.overview.description)
                            .font(Components.isRegular(.system(size: 14), .system(size: 16)))
                            .foregroundStyle(.deepGray)
                    }

                    resultsSection("Эмоциональная совместимость") {
                        VStack(spacing: 15) {
                            ForEach(result.emotionalBar, id: \.self) { bar in
                                Components.emotionalProfileBar(bar.title, bar.value)
                            }
                        }
                        .padding(.top, 5)
                    }

                    ForEach(result.sections, id: \.self) { section in
                        resultsSection(section.selectedTest.rawValue) {
                            Text(section.description)
                                .font(Components.isRegular(.system(size: 14), .system(size: 16)))
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
                .stroke(Color.deepBlue.opacity(0.18), lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(min(max(value, 0), 100)) / 100)
                .stroke(Color.deepBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 5) {
                Text("\(min(max(value, 0), 100))%")
                    .font(Components.isRegular(.title3, .title2))
                    .bold()
                    .foregroundStyle(Color.deepBlue)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("СОВМЕСТИМОСТЬ")
                    .font(Components.isRegular(.caption2, .caption))
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
                .font(Components.isRegular(.callout, .default))
                .bold()
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(12, .white, true)
    }
    
    private func resultsWithNumbersSection(_ type: LoveLanguageTypes,
                                           _ title: String,
                                           _ description: String) -> some View {
        HStack(alignment: .top) {
            Text(type.number)
                .font(Components.isRegular(.callout, .default))
                .fontWeight(.semibold)
                .foregroundStyle(type.numberColor)
                .padding(10)
                .background(type.numberColor.opacity(0.15))
                .clipShape(Circle())
                .frame(width: 35, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 7) {
                Text(type.rawValue.uppercased())
                    .font(Components.isRegular(.footnote, .system(size: 15)))
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                
                Text(title)
                    .font(Components.isRegular(.system(size: 14), .callout))
                    .bold()
                
                Text(description)
                    .font(Components.isRegular(.footnote, .system(size: 15)))
                    .foregroundStyle(.deepGray)
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    enum LoveLanguageTypes: String {
        case main = "Основной"
        case additional = "Дополнительный"
        case spark = "Искра"
        case potentional = "Потенциал"
        
        var number: String {
            switch self {
                case .main, .spark:
                    return "1"
                case .additional, .potentional:
                    return "2"
            }
        }
        
        var numberColor: Color {
            switch self {
                case .main:
                    return .red
                case .additional:
                    return .blue
                case .spark:
                    return .blue
                case .potentional:
                    return .yellow
            }
        }
    }
}

#Preview {
    NavigationStack {
        CompatibilityResultView(result: .mock)
    }
}
