//
//  TestResultsView.swift
//  Aura
//
//  Created by ddorsat on 11.05.2026.
//

import SwiftUI

struct PersonalityResultView: View {
    let result: PersonalityResultModel

    var body: some View {
        ZStack {
            Components.backgroundColor()

            ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack {
                            HStack(spacing: 15) {
                                Text(result.zodiacSign)
                                    .fontWeight(.semibold)
                                    .padding(10)
                                    .background(.lightPurple)
                                    .clipShape(Circle())
                                
                                Text(result.name.capitalized)
                                    .font(Components.isRegular(.title3, .title2))
                                    .fontDesign(.rounded)
                                    .bold()
                            }
                            .padding(.vertical, 20)
                            
                            VStack(alignment: .center, spacing: 15) {
                                HStack {
                                    ForEach(result.selectedTests, id: \.self) { test in
                                        Components.testCellImage(test.icon, test.color, .default, 30, true)
                                    }
                                }
                                
                                Text(result.archetypeTitle)
                                    .font(Components.isRegular(.default, .system(size: 19)))
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                                
                                Text(result.archetypeSubtitle)
                                    .font(Components.isRegular(.footnote, .system(size: 15)))
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
                                .font(Components.isRegular(.system(size: 14), .system(size: 16)))
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
                                    .font(Components.isRegular(.system(size: 14), .system(size: 16)))
                                    .foregroundStyle(.deepGray)
                                
                                VStack(spacing: 15) {
                                    ForEach(Array(test.items.enumerated()), id: \.element) { index, item in
                                        TestResultCellView(test: item.title, description: item.description)
                                        
                                        if index < test.items.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .testTopicsModifier()
                            }
                        }
                    }
                    .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Результаты теста")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension PersonalityResultView {
    private func section<Content: View>(_ title: String,
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
}

#Preview {
    NavigationStack {
        PersonalityResultView(result: .mock)
    }
}
