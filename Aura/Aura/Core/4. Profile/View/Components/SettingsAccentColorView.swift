//
//  SettingsAccentColorView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SettingsAccentColorView: View {
    let color: Color
    let isSelected: Bool
    let onTapHandler: () -> Void
    
    var body: some View {
        Button(action: onTapHandler) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(Circle() .stroke(Color.white, lineWidth: 1))
                .overlay(Circle() .stroke(isSelected ? Color(.systemGray2) : Color.clear, lineWidth: 5))
                .shadow(color: .black.opacity(0.1), radius: 2)
        }
    }
}

#Preview {
    SettingsAccentColorView(color: .red, isSelected: false) {
        
    }
}
