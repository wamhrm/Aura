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
            case .light:
                return .light
            case .dark:
                return .dark
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
            case .blue:
                return .accentBlue
            case .purple:
                return .accentPurple
            case .red:
                return .accentRed
            case .teal:
                return .accentTeal
            case .orange:
                return .accentOrange
        }
    }

    static func color(_ value: String) -> Color {
        AccentColorOption(rawValue: value)?.color ?? AccentColorOption.blue.color
    }
}
