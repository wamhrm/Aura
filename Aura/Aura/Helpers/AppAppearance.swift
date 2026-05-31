//
//  AppAppearance.swift
//  Aura
//
//  Created by ddorsat on 29.05.2026.
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case light
    case dark

    var colorScheme: ColorScheme {
        switch self {
            case .light: .light
            case .dark: .dark
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue
    case purple
    case red
    case teal
    case orange

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
        AccentColorOption(rawValue: value)?.color ?? AccentColorOption.blue.color
    }
}
