//
//  AuraApp.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var authService: AuthService
    @StateObject private var contentService: ContentService

    @AppStorage(Constants.selectedThemeKey, store: Constants.userDefaults) private var selectedTheme = AppTheme.light
    @AppStorage(Constants.accentColorKey, store: Constants.userDefaults) private var accentColor = AccentColorOption.blue.rawValue

    init() {
        let networkService = NetworkService()
        let authService = AuthService(networkService: networkService)
        _authService = StateObject(wrappedValue: authService)
        _contentService = StateObject(wrappedValue: ContentService(networkService: networkService,
                                                                   authService: authService))
    }

    var body: some Scene {
        WindowGroup {
            RootView(authService: authService,
                     contentService: contentService)
                .preferredColorScheme(selectedTheme.colorScheme)
                .tint(AccentColorOption.color(accentColor))
        }
    }
}
