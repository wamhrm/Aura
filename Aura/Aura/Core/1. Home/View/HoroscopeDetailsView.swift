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
            Components.backgroundColor()
            
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 10) {
                        Text(horoscope.type.icon)
                            .font(.system(size: 40))
                            .padding(.top, 6)
                            .padding(.vertical, 18)
                        
                        Text(horoscope.type.rawValue)
                            .font(.title2)
                            .fontDesign(.monospaced)
                            .bold()
                        
                        Components.horoscopeDate(true)
                            .padding(10)
                            .background(Color(.systemGray6).opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.softPurple, .libra],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .addSparkles()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("На этой неделе")
                            .fontWeight(.semibold)
                        
                        Text("""
                            "\(horoscope.description)"
                            """)
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                            .fontWeight(.medium)
                            .italic()
                    }
                    .padding(23)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.appBackground)
                    .backgroundWithShape(20, true)
                    
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
                        
                        ForEach(HoroscopeDetailsCellType.allCases, id: \.self) { type in
                            HoroscopeDetailsCellView(type: type, description: "Эта неделя может стать особенно тяжелой для вашего сердца. Откровенный разговор с близким человеком укрепит ваши отношения и принесет давно ожидаемое понимание.")
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Мой гороскоп")
            .navigationBarTitleDisplayMode(.inline)
            .bottomAreaPadding()
        }
    }
}

#Preview {
    HoroscopeDetailsView(horoscope: .mock)
}
