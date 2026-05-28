//
//  AuraApp.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var contentService = ContentService()

    @AppStorage(Constants.selectedThemeKey) private var selectedTheme = AppTheme.light
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some Scene {
        WindowGroup {
            MainTabView(authService: authService,
                        contentService: contentService)
                .preferredColorScheme(selectedTheme.colorScheme)
                .tint(Components.handleAccentColor(accentColor))
        }
    }
}
