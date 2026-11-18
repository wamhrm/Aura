//
//  HoroscopeCellView.swift
//  Aura
//
//  Created by wamhrm on 04.05.2026.
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
                        .font(Adaptive.size(.title3, .system(size: 21), .title2))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(horoscope.type.title)
                            .font(Adaptive.size(.callout, .default, .default))
                            .fontWeight(.semibold)
                        
                        HoroscopeDateView(dateStart: horoscope.dateStart,
                                          dateEnd: horoscope.dateEnd,
                                          isCellDetails: false)
                    }
                }
                
                Text(horoscope.description)
                    .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
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
            .clipShape(.rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fieldBackground, lineWidth: 1))
        }
    }
}

enum HoroscopeTypes: String, CaseIterable, Codable {
    case aries, taurus, gemini, cancer, leo, virgo, libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var title: String {
        switch self {
            case .aries: AppLanguage.text("Овен")
            case .taurus: AppLanguage.text("Телец")
            case .gemini: AppLanguage.text("Близнецы")
            case .cancer: AppLanguage.text("Рак")
            case .leo: AppLanguage.text("Лев")
            case .virgo: AppLanguage.text("Дева")
            case .libra: AppLanguage.text("Весы")
            case .scorpio: AppLanguage.text("Скорпион")
            case .sagittarius: AppLanguage.text("Стрелец")
            case .capricorn: AppLanguage.text("Козерог")
            case .aquarius: AppLanguage.text("Водолей")
            case .pisces: AppLanguage.text("Рыбы")
        }
    }
    
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
