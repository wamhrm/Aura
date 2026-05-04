//
//  HoroscopeCellView.swift
//  Aura
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct HoroscopeCellView: View {
    let type: HoroscopeType
    let isHorizontal: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                Image(systemName: "globe.asia.australia")
                    .imageScale(.large)
                    .padding(10)
                    .background(Circle() .fill(Color(.systemGray5)))
                
                VStack(alignment: .leading) {
                    Text(type.rawValue)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 7) {
                        Text(type.startingDate)
                        
                        Rectangle()
                            .frame(width: 5, height: 1)
                        
                        Text(type.endingDate)
                    }
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.horoscopeDate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Text("""
                 "Фортуна благоволит смелым сегодня. Сделайте тот шаг, о котором думали"
                 """)
                .foregroundStyle(.horoscopeDate)
                .fontWeight(.medium)
                .italic()
                .lineLimit(isHorizontal ? 3 : .max)
        }
        .padding(.horizontal)
        .padding(.vertical, 25)
        .frame(width: isHorizontal ? 300 : .infinity, height: 180)
        .background(type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

enum HoroscopeType: String {
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
    
    var backgroundColor: Color {
        switch self {
            case .aries: return .aries
            case .taurus: return .taurus
            case .gemini: return .gemini
            case .cancer: return .cancer
            case .leo: return .leo
            case .virgo: return .virgo
            case .libra: return .libra
            case .scorpio: return .scorpio
            case .sagittarius: return .sagittarius
            case .capricorn: return .capricorn
            case .aquarius: return .aquarius
            case .pisces: return .pisces
        }
    }
    
    var startingDate: String {
        switch self {
            case .aries: return "21 мар"
            case .taurus: return "20 апр"
            case .gemini: return "21 май"
            case .cancer: return "21 июн"
            case .leo: return "23 июл"
            case .virgo: return "23 авг"
            case .libra: return "23 сен"
            case .scorpio: return "23 окт"
            case .sagittarius: return "22 ноя"
            case .capricorn: return "22 дек"
            case .aquarius: return "20 янв"
            case .pisces: return "19 фев"
        }
    }

    var endingDate: String {
        switch self {
            case .aries: return "19 апр"
            case .taurus: return "20 май"
            case .gemini: return "20 июн"
            case .cancer: return "22 июл"
            case .leo: return "22 авг"
            case .virgo: return "22 сен"
            case .libra: return "22 окт"
            case .scorpio: return "21 ноя"
            case .sagittarius: return "21 дек"
            case .capricorn: return "19 янв"
            case .aquarius: return "18 фев"
            case .pisces: return "20 мар"
        }
    }
}

#Preview {
    ZStack {
        Color.cyan.opacity(0.5).ignoresSafeArea()
        ScrollView {
            VStack(spacing: 25) {
                HoroscopeCellView(type: .aries, isHorizontal: true)
                HoroscopeCellView(type: .taurus, isHorizontal: true)
                HoroscopeCellView(type: .gemini, isHorizontal: true)
                HoroscopeCellView(type: .cancer, isHorizontal: true)
                HoroscopeCellView(type: .leo, isHorizontal: true)
                HoroscopeCellView(type: .virgo, isHorizontal: true)
                HoroscopeCellView(type: .libra, isHorizontal: true)
                HoroscopeCellView(type: .scorpio, isHorizontal: true)
                HoroscopeCellView(type: .sagittarius, isHorizontal: true)
                HoroscopeCellView(type: .capricorn, isHorizontal: true)
                HoroscopeCellView(type: .aquarius, isHorizontal: true)
                HoroscopeCellView(type: .pisces, isHorizontal: true)
            }
            .padding(.horizontal)
        }
    }
}
