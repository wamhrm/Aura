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

nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case russian = "ru"
    case english = "en"

    var id: String { rawValue }

    static var current: AppLanguage {
        guard let raw = Constants.userDefaults.string(forKey: Constants.appLanguage) else { return .system }
        return AppLanguage(rawValue: raw) ?? .system
    }

    nonisolated(unsafe) static var localeOverride: Locale?

    static var resolvedLocale: Locale {
        localeOverride ?? current.locale
    }

    static var requestCode: String {
        if let code = resolvedLanguageCode {
            return code
        }
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "ru"
        return preferred.hasPrefix("en") ? "en" : "ru"
    }

    static func text(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: localizationBundle, locale: resolvedLocale)
    }

    private static var localizationBundle: Bundle {
        let code = resolvedLanguageCode
        guard let code,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    private static var resolvedLanguageCode: String? {
        if let localeOverride {
            return localeOverride.language.languageCode?.identifier
        }
        switch current {
            case .system:
                return nil
            case .russian:
                return "ru"
            case .english:
                return "en"
        }
    }

    var title: String {
        switch self {
            case .system: Self.text("Как в iPhone")
            case .russian: "Русский"
            case .english: "English"
        }
    }

    var locale: Locale {
        switch self {
            case .system:
                .autoupdatingCurrent
            case .russian, .english:
                locale(languageCode: rawValue)
        }
    }

    private func locale(languageCode: String) -> Locale {
        let region = Locale.autoupdatingCurrent.region
        var components = Locale.Components(languageCode: Locale.LanguageCode(languageCode),
                                           languageRegion: region)
        components.region = region
        return Locale(components: components)
    }
}
