//
//  TestCellView.swift
//  Aura
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct TestCellView: View {
    let type: TestType
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundStyle(Color(type.color))
                .padding(10)
                .frame(width: 45, height: 45)
                .background(RoundedRectangle(cornerRadius: 15) .fill(Color(type.color).opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(type.rawValue)
                    .fontWeight(.semibold)
                Text(type.description)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.horoscopeDate)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(20)
    }
}

enum TestType: String, CaseIterable {
    case astrology = "Глубокий разбор астрологии"
    case numerology = "Анализ нумерологии"
    case elements = "Анализ элементов"
    case loveLanguage = "Сканирование языка любви"
    case attachmentStyle = "Тест на стиль привязанности"
    case emotionalIntelligence = "Эмоциональный интеллект"
    case sexualCompatibility = "Сексуальная совместимость"
    
    var description: String {
        switch self {
            case .astrology: return "Поймите выравнивание ваших планет"
            case .numerology: return "Откройте секреты числа вашего пути"
            case .elements: return "Вы Огонь, Земля, Воздух или Вода?"
            case .loveLanguage: return "Как вы даёте и получаете любовь"
            case .attachmentStyle: return "Раскройте ваши паттерны отношений"
            case .emotionalIntelligence: return "Достаточно ли осознанный вы человек?"
            case .sexualCompatibility: return "Исследуйте химию и интимную связь"
        }
    }
    
    var icon: String {
        switch self {
            case .astrology: return "sparkles"
            case .numerology: return "number"
            case .elements: return "drop"
            case .loveLanguage: return "heart"
            case .attachmentStyle: return "person.2"
            case .emotionalIntelligence: return "brain"
            case .sexualCompatibility: return "flame"
        }
    }
    
    var color: UIColor {
        switch self {
            case .astrology: return .systemIndigo
            case .numerology: return .systemBlue
            case .elements: return .systemGreen
            case .loveLanguage: return .systemRed
            case .attachmentStyle: return .systemOrange
            case .emotionalIntelligence: return .systemTeal
            case .sexualCompatibility: return .systemRed
        }
    }
}

#Preview {
    ForEach(TestType.allCases, id: \.self) { test in
        TestCellView(type: test)
    }
    .padding(.horizontal)
}
