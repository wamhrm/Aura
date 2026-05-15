//
//  TestResultsView.swift
//  Aura
//
//  Created by ddorsat on 11.05.2026.
//

import SwiftUI

struct PersonalityResultView: View {
    @ObservedObject var vm: HomeViewModel
    
    var body: some View {
        ZStack {
            Components.backgroundColor()
            
            if let result = vm.personalityResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack {
                            HStack(spacing: 15) {
                                Text(result.zodiacSign)
                                    .fontWeight(.semibold)
                                    .padding(10)
                                    .background(.lightPurple)
                                    .clipShape(Circle())
                                
                                Text(result.name)
                                    .font(.title2)
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
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                                
                                Text(result.archetypeSubtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.deepGray)
                                    .multilineTextAlignment(.center)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 10)
                        
                        section(result.overview.title) {
                            Text(result.overview.description)
                                .font(.callout)
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
                                    .font(.callout)
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
            } else {
                ContentUnavailableView {
                    Text("Результаты пока недоступны")
                }
            }
        }
        .navigationTitle("Результаты теста")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
    }
}

extension PersonalityResultView {
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .bold()
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(15, true)
    }
}

#Preview {
    NavigationStack {
        PersonalityResultView(vm: HomeViewModel(authService: AuthService(),
                                                 psychologyService: PsychologyService()))
    }
}
