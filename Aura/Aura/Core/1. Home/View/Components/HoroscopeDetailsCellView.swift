//
//  HoroscopeDetailsCellView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct HoroscopeDetailsCellView: View {
    let type: HoroscopeDetailsCellType
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: type.icon)
                    .font(Components.displaySize(.title3, .title2))
                    .foregroundStyle(Color(type.color))
                    .padding(10)
                    .frame(width: Components.displaySize(35, 35),
                           height: Components.displaySize(35, 35))
                    .background(RoundedRectangle(cornerRadius: 8) .fill(Color(type.color).opacity(0.2)))
                
                Text(type.rawValue)
                    .font(Components.displaySize(.callout, .default))
                    .bold()
            }
        
            Text(description)
                .font(.system(size: Components.displaySize(14, 15)))
                .foregroundStyle(.deepGray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(12, .cardBackground, true)
        .shadow(color: Color(type.color).opacity(0.15), radius: 2)
    }
}

enum HoroscopeDetailsCellType: String, CaseIterable, Codable {
    case love = "Любовь"
    case health = "Здоровье"
    case work = "Работа"
    
    var icon: String {
        switch self {
            case .love:
                return "heart"
            case .health:
                return "cross.case.fill"
            case .work:
                return "briefcase.fill"
        }
    }
    
    var color: UIColor {
        switch self {
            case .love:
                return .systemRed
            case .health:
                return .systemIndigo
            case .work:
                return .systemGreen
        }
    }
}

#Preview {
    HoroscopeDetailsCellView(type: .love, description: "Эта неделя может стать особенно тяжелой для вашего сердца. Откровенный разговор с близким человеком укрепит ваши отношения и принесет давно ожидаемое понимание.")
}
