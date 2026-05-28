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
            Components.backgroundColor()

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    VStack {
                        HStack(spacing: 15) {
                            Text(result.zodiacSign)
                                .font(Components.displaySize(.default, .title3))
                                .fontWeight(.semibold)
                                .padding(10)
                                .background(.lightPurple)
                                .clipShape(Circle())
                            
                            Text(result.name.capitalized)
                                .font(Components.displaySize(.title3, .title2))
                                .fontDesign(.rounded)
                                .bold()
                        }
                        .padding(.vertical, Components.displaySize(20, 22))
                        
                        VStack(alignment: .center, spacing: Components.displaySize(15, 17)) {
                            HStack {
                                ForEach(result.selectedTests, id: \.self) { test in
                                    Components.testCellImage(test.icon, test.color, .default, 30, true)
                                }
                            }
                            
                            Text(result.archetypeTitle)
                                .font(Components.displaySize(.default, .system(size: 19)))
                                .foregroundStyle(Components.handleAccentColor(accentColor))
                                .fontWeight(.semibold)
                            
                            Text(result.archetypeSubtitle)
                                .font(Components.displaySize(.footnote, .system(size: 14)))
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
                            .font(.system(size: Components.displaySize(14, 15)))
                            .foregroundStyle(.deepGray)
                    }
                    
                    section("Внутренний мир") {
                        VStack(spacing: 15) {
                            ForEach(result.emotionalBar, id: \.self) { bar in
                                Components.emotionalProfileBar(bar.title, bar.value)
                            }
                        }
                        .padding(.top, 5)
                    }
                    
                    ForEach(result.sections, id: \.self) { test in
                        section(test.selectedTest.rawValue) {
                            Text(test.description)
                                .font(Components.displaySize(.system(size: 15), .callout))
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
                .font(Components.displaySize(.system(size: 15), .default))
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
