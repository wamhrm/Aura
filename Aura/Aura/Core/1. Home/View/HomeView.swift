//
//  HomeView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Components.backgroundColor()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 35) {
                        HStack(spacing: 15) {
                            Image(systemName: "globe.asia.australia")
                                .font(.title)
                                .padding(10)
                                .background(Circle() .fill(
                                    LinearGradient(colors: [.purple.opacity(0.35),
                                                            .pink.opacity(0.05)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)))
                                .overlay(Circle() .stroke(.white, lineWidth: 5))
                                .clipShape(Circle())
                                
                            Text("Добро пожаловать")
                                .fontWeight(.semibold)
                                .fontDesign(.monospaced)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("ИНСАЙТ ДНЯ")
                                .fontWeight(.heavy)

                            Text("""
                                 "Сегодня лучше вести спокойные беседы, чем давить эмоционально"
                                 """)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .italic()
                        }
                        .foregroundStyle(.white)
                        .padding(25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 125)
                        .background(.feedQuote)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                        .padding(.top, -15)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            headerText("Гороскопы на сегодня", "Все знаки") {
                                
                            }
                            
                            ScrollView(.horizontal) {
                                LazyHGrid(rows: [GridItem()], spacing: 20) {
                                    ForEach(0..<5) { _ in
                                        HoroscopeCellView(type: .aquarius, isHorizontal: true)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .scrollIndicators(.hidden)
                        }
                        
                        HStack {
                            Text("Проверьте вашу совместимость с кем-то")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.white)
                                .lineSpacing(8)
                                
                            Spacer()
                                
                            Image(systemName: "sparkles")
                                .imageScale(.large)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color(.systemGray6).opacity(0.15))
                                .clipShape(Circle())
                        }
                        .padding(25)
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            headerText("Проверьте себя", "Все тесты") {
                                
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(TestType.allCases.prefix(3), id: \.self) { test in
                                    TestCellView(type: test)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .navigationTitle("Главная")
                .navigationBarTitleDisplayMode(.inline)
                .bottomAreaPadding()
            }
        }
    }
}

extension HomeView {
    private func headerText(_ title: String, _ buttonTitle: String,
                           _ onTapHandler: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
                .padding(.leading, 2)
            
            Spacer()
            
            Button {
                onTapHandler()
            } label: {
                Text(buttonTitle)
                    .foregroundStyle(.blue)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
}
