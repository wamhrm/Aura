//
//  SettingsSheetButtonView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SettingsSheetThemesButtonView: View {
    let type: SettingsSheetThemesButtonTypes
    let isSelected: Bool
    let onTapHandler: () -> Void
    
    var body: some View {
        Button(action: onTapHandler) {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                
                Text(type.rawValue)
                    .font(.callout)
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.25), lineWidth: 1))
        }
    }
}

enum SettingsSheetThemesButtonTypes: String {
    case bright = "Светлая"
    case dark = "Темная"
    
    var icon: String {
        switch self {
            case .bright:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
        }
    }
}

#Preview {
    SettingsSheetThemesButtonView(type: .bright, isSelected: false) {
        
    }
}
