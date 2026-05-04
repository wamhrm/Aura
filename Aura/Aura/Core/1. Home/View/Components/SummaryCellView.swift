//
//  SummaryCellView.swift
//  Aura
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct SummaryCellView: View {
    let type: SummaryCellType
    let value: String
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                    .resizable()
                    .foregroundStyle(.horoscopeDate)
                    .fontWeight(.medium)
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .clipped()
                
                Text(type.rawValue)
                    .font(.callout)
                    .foregroundStyle(.horoscopeDate)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
        }
    }
}

enum SummaryCellType: String, CaseIterable {
    case attachmentStyle = "Стиль привязанности"
    case emotionalIntensity = "Эмоциональная интенсивность"
    case trustSpeed = "Скорость доверия"
    case freedomNeed = "Потребность в свободе"
    case loveLanguage = "Язык любви"
    case jealousySensitivity = "Чувствительность к ревности"
    case stabilityLevel = "Уровень стабильности"
    
    var icon: String {
        switch self {
            case .attachmentStyle:
                return "shield"
            case .loveLanguage:
                return "flame"
            case .trustSpeed:
                return "target"
            case .emotionalIntensity:
                return "drop"
            case .freedomNeed:
                return "heart"
            case .jealousySensitivity:
                return "brain"
            case .stabilityLevel:
                return "person"
        }
    }
}

#Preview {
    SummaryCellView(type: .attachmentStyle, value: "Тревожный")
}
