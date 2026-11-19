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

    var title: LocalizedStringResource {
        switch self {
            case .blue: "Синий"
            case .purple: "Фиолетовый"
            case .red: "Красный"
            case .teal: "Бирюзовый"
            case .orange: "Оранжевый"
        }
    }

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

nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case russian = "ru"
    case english = "en"

    var id: String { rawValue }

    static var current: AppLanguage {
        guard let raw = Constants.userDefaults.string(forKey: Constants.appLanguage) else { return .system }
        return AppLanguage(rawValue: raw) ?? .system
    }

    static var resolvedLocale: Locale { current.locale }

    static var requestCode: String { current.languageCode }

    var languageCode: String {
        switch self {
            case .system: Bundle.main.preferredLocalizations.first ?? Self.russian.rawValue
            case .russian, .english: rawValue
        }
    }

    static func text(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = resolvedLocale
        return String(localized: resource)
    }

    var locale: Locale {
        let region = Locale.autoupdatingCurrent.region
        var components = Locale.Components(languageCode: Locale.LanguageCode(languageCode),
                                           languageRegion: region)
        components.region = region
        return Locale(components: components)
    }
}
