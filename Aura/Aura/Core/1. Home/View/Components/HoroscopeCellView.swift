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
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(horoscope.type.rawValue)
                            .fontWeight(.semibold)
                        
                        Components.horoscopeDate(false)
                    }
                }
                
                Text("""
                     "\(horoscope.description)"
                     """)
                    .foregroundStyle(.deepGray)
                    .fontWeight(.medium)
                    .italic()
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.black)
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.lightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15) .stroke(Color(.systemGray6), lineWidth: 1))
        }
    }
}

enum HoroscopeType: String, CaseIterable {
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
            case .aries: return "♈️"
            case .taurus: return "♉️"
            case .gemini: return "♊️"
            case .cancer: return "♋️"
            case .leo: return "♌️"
            case .virgo: return "♍️"
            case .libra: return "♎️"
            case .scorpio: return "♏️"
            case .sagittarius: return "♐️"
            case .capricorn: return "♑️"
            case .aquarius: return "♒️"
            case .pisces: return "♓️"
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
