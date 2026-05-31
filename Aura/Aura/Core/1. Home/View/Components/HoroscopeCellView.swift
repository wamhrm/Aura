//
//  HoroscopeCellView.swift
//  Aura
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct HoroscopeCellView: View {
    let horoscope: HoroscopeModel
    let onTapHandler: () -> Void

    var body: some View {
        Button(action: onTapHandler) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 18) {
                    Text(horoscope.type.icon)
                        .font(Adaptive.size(.title3, .title2))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(horoscope.type.rawValue)
                            .font(Adaptive.size(.callout, .default))
                            .fontWeight(.semibold)
                        
                        HoroscopeDateView(dateStart: horoscope.dateStart, dateEnd: horoscope.dateEnd, isCellDetails: false)
                    }
                }
                
                Text("""
                     "\(horoscope.description)"
                     """)
                .font(Adaptive.size(.footnote, .system(size: 15)))
                .italic()
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.primaryText)
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.lightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fieldBackground, lineWidth: 1))
        }
    }
}

enum HoroscopeTypes: String, CaseIterable, Codable {
    case aries = "Овен"
    case taurus = "Телец"
    case gemini = "Близнецы"
    case cancer = "Рак"
    case leo = "Лев"
    case virgo = "Дева"
    case libra = "Весы"
    case scorpio = "Скорпион"
    case sagittarius = "Стрелец"
    case capricorn = "Козерог"
    case aquarius = "Водолей"
    case pisces = "Рыбы"
    
    var icon: String {
        switch self {
            case .aries: "♈️"
            case .taurus: "♉️"
            case .gemini: "♊️"
            case .cancer: "♋️"
            case .leo: "♌️"
            case .virgo: "♍️"
            case .libra: "♎️"
            case .scorpio: "♏️"
            case .sagittarius: "♐️"
            case .capricorn: "♑️"
            case .aquarius: "♒️"
            case .pisces: "♓️"
        }
    }
}

#Preview {
    ZStack {
        Color.cyan.opacity(0.5).ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 25) {
                HoroscopeCellView(horoscope: .mock) {
                    
                }
            }
            .padding(.horizontal)
        }
    }
}
