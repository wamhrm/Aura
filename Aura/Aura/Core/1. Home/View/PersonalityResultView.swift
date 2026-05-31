//
//  TestResultsView.swift
//  Aura
//
//  Created by ddorsat on 11.05.2026.
//

import SwiftUI

struct PersonalityResultView: View {
    let result: PersonalityResultModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    VStack {
                        HStack(spacing: 15) {
                            Text(result.zodiacSign)
                                .font(Adaptive.size(.default, .title3))
                                .fontWeight(.semibold)
                                .padding(10)
                                .background(.lightPurple)
                                .clipShape(Circle())
                            
                            Text(result.name.capitalized)
                                .font(Adaptive.size(.title3, .title2))
                                .fontDesign(.rounded)
                                .bold()
                        }
                        .padding(.vertical, Adaptive.size(20, 22))
                        
                        VStack(alignment: .center, spacing: Adaptive.size(15, 17)) {
                            HStack {
                                ForEach(result.selectedTests, id: \.self) { test in
                                    TestCellImage(icon: test.icon, color: test.color, iconSize: .default, backgroundSize: 30, isResults: true)
                                }
                            }
                            
                            Text(result.archetypeTitle)
                                .font(Adaptive.size(.default, .system(size: 19)))
                                .foregroundStyle(AccentColorOption.color(accentColor))
                                .fontWeight(.semibold)
                            
                            Text(result.archetypeSubtitle)
                                .font(Adaptive.size(.footnote, .system(size: 14)))
                                .foregroundStyle(.deepGray)
                                .multilineTextAlignment(.center)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: 300, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                    
                    section(result.overview.title) {
                        Text(result.overview.description)
                            .font(.system(size: Adaptive.size(14, 15)))
                            .foregroundStyle(.deepGray)
                    }
                    
                    section("Внутренний мир") {
                        VStack(spacing: 15) {
                            ForEach(result.emotionalBar, id: \.self) { bar in
                                EmotionalProfileBar(type: bar.title, value: bar.value)
                            }
                        }
                        .padding(.top, 5)
                    }
                    
                    ForEach(result.sections, id: \.self) { test in
                        section(test.selectedTest.rawValue) {
                            Text(test.description)
                                .font(Adaptive.size(.system(size: 15), .callout))
                                .foregroundStyle(.deepGray)
                            
                            VStack(spacing: 15) {
                                ForEach(Array(test.items.enumerated()), id: \.element) { index, item in
                                    TestResultCellView(test: item.title,
                                                       description: item.description)
                                    
                                    if index < test.items.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .testTopicsModifier()
                        }
                    }
                }
                .bottomAreaPadding(15)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Результат персонального теста")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension PersonalityResultView {
    private func section<Content: View>(_ title: String,
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
}

#Preview {
    NavigationStack {
        PersonalityResultView(result: .mock)
    }
}
