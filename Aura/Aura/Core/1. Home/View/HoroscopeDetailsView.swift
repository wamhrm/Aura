//
//  HoroscopeDetailsView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct HoroscopeDetailsView: View {
    let horoscope: HoroscopeModel
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 12) {
                        Text(horoscope.type.icon)
                            .font(.system(size: Adaptive.size(30, 32)))
                            .padding(.top, 8)
                            .padding(.vertical, 18)
                        
                        Text(horoscope.type.rawValue)
                            .font(.title3)
                            .fontDesign(.monospaced)
                            .bold()
                        
                        HoroscopeDateView(dateStart: horoscope.dateStart, dateEnd: horoscope.dateEnd, isCellDetails: true)
                            .padding(10)
                            .background(Color.fieldBackground.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.softPurple, .libra],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .addSparkles()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("На этой неделе")
                            .font(Adaptive.size(.callout, .default))
                            .fontWeight(.semibold)
                        
                        Text("""
                            "\(horoscope.description)"
                            """)
                            .font(.system(size: Adaptive.size(14, 15)))
                            .italic()
                            .foregroundStyle(.deepGray)
                            .fontWeight(.medium)
                    }
                    .padding(23)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.appBackground)
                    .backgroundWithShape(12, .cardBackground, true)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Сферы жизни")
                                .padding(.leading, 4)
                                .bold()
                            
                            Spacer()
                            
                            Text("Эта неделя")
                                .foregroundStyle(.deepGray)
                                .fontWeight(.medium)
                        }
                        .font(Adaptive.size(.system(size: 15), .default))
                        
                        ForEach(horoscope.items, id: \.self) { item in
                            HoroscopeDetailsCellView(type: item.title, description: item.description)
                        }
                    }
                }
                .bottomAreaPadding(15)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Мой гороскоп")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HoroscopeDetailsView(horoscope: .mock)
}
