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
                    .font(.title2)
                    .foregroundStyle(Color(type.color))
                    .padding(10)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color(type.color).opacity(0.2)))
                
                Text(type.rawValue)
                    .bold()
            }
        
            Text(description)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.deepGray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(15, true)
        .shadow(color: Color(type.color).opacity(0.15), radius: 2)
    }
}

enum HoroscopeDetailsCellType: String, CaseIterable {
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
