//
//  TestResultsView.swift
//  Aura
//
//  Created by ddorsat on 11.05.2026.
//

import SwiftUI

struct PersonalityResultsView: View {
    @ObservedObject var vm: HomeViewModel
    
    var body: some View {
        ZStack {
            Components.backgroundColor()

            if let result = vm.personalityAnalysisResult {
                resultsContent(result)
            } else {
                Text("Результат пока недоступен")
                    .font(.callout)
                    .foregroundStyle(.deepGray)
                    .padding()
                    .backgroundWithShape(15, true)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Результат персонального теста")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
    }
}

extension PersonalityResultsView {
    private func resultsContent(_ result: PersonalityAnalysisResult) -> some View {
        ScrollView {
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    Text(result.zodiacSign ?? "✦")
                        .fontWeight(.semibold)
                        .padding(10)
                        .background(.lightPurple)
                        .clipShape(Circle())

                    Text(result.userName)
                        .font(.title2)
                        .fontDesign(.monospaced)
                        .bold()
                }
                .padding(.vertical, 15)

                HStack(spacing: 15) {
                    ForEach(result.selectedTests.compactMap(TestTypes.init(apiID:)), id: \.self) { test in
                        Components.testCellImage(test.icon, test.color, .default, 30, true)
                    }
                }

                VStack(alignment: .center, spacing: 10) {
                    Text(result.archetypeTitle)
                        .foregroundStyle(.deepBlue)
                        .bold()

                    Text(result.archetypeSubtitle)
                        .font(.callout)
                        .foregroundStyle(.deepGray)
                }
                .multilineTextAlignment(.center)
                .frame(width: 300)
                .padding(.bottom, 10)

                Components.resultsSection(result.overview.title) {
                    Text(result.overview.body)
                        .font(.callout)
                        .foregroundStyle(.deepGray)
                }

                if !result.scales.isEmpty {
                    Components.resultsSection("Внутренний мир") {
                        VStack(spacing: 15) {
                            ForEach(Array(result.scales.enumerated()), id: \.offset) { _, scale in
                                scaleBar(scale)
                            }
                        }
                        .padding(.top, 5)
                    }
                }

                ForEach(Array(result.sections.enumerated()), id: \.offset) { _, section in
                    Components.resultsSection(section.title) {
                        Text(section.body)
                            .font(.callout)
                            .foregroundStyle(.deepGray)

                        if !section.items.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(Array(section.items.enumerated()), id: \.offset) { index, item in
                                    if index > 0 {
                                        Divider()
                                    }

                                    resultItem(item)
                                }
                            }
                            .testTopicsModifier()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }

    private func scaleBar(_ scale: PersonalityScale) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(scale.title)

                Spacer()

                Text("\(clampedScaleValue(scale.value))/10")
            }
            .font(.system(size: 14))
            .fontWeight(.semibold)
            .foregroundStyle(.deepGray)

            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray6))

                    Capsule()
                        .fill(LinearGradient(colors: [.purple, .softPurple],
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: bar.size.width * (CGFloat(clampedScaleValue(scale.value)) / CGFloat(10)))
                }
            }
            .frame(height: 10)
        }
    }

    private func resultItem(_ item: PersonalityResultItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.callout)
                .fontWeight(.semibold)

            Text(item.description)
                .font(.callout)
                .foregroundStyle(.deepGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func clampedScaleValue(_ value: Int) -> Int {
        min(max(value, 1), 10)
    }
}

#Preview {
    NavigationStack {
        PersonalityResultsView(vm: HomeViewModel(authService: AuthService(),
                                                 personalityAnalysisService: MockPersonalityAnalysisService()))
    }
}
