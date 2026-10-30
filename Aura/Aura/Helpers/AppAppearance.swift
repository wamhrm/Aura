//
//  AppAppearance.swift
//  Aura
//
//  Created by wamhrm on 29.05.2026.
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case light, dark

    var colorScheme: ColorScheme {
        switch self {
            case .light: .light
            case .dark: .dark
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue, purple, red, teal, orange

    var id: String { rawValue }

    var color: Color {
        switch self {
            case .blue: .accentBlue
            case .purple: .accentPurple
            case .red: .accentRed
            case .teal: .accentTeal
            case .orange: .accentOrange
        }
    }

    static func color(_ value: String) -> Color {
        (AccentColorOption(rawValue: value) ?? .blue).color
    }
}
