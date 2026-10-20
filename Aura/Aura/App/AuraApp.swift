//
//  AuraApp.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var authService: AuthService
    @StateObject private var contentService: ContentService

    @AppStorage(Constants.selectedThemeKey) private var selectedTheme = AppTheme.light
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    private let storage: LocalStorage

    init() {
        let keychain = KeychainHelper()
        let networkService = NetworkService(keychain: keychain)
        let storage = LocalStorage()
        storage.migrateLegacyUserDefaults()

        self.storage = storage
        _authService = StateObject(wrappedValue: AuthService(networkService: networkService,
                                                             keychain: keychain,
                                                             storage: storage))
        _contentService = StateObject(wrappedValue: ContentService(networkService: networkService))
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(authService: authService,
                        contentService: contentService,
                        storage: storage)
                .preferredColorScheme(selectedTheme.colorScheme)
                .tint(AccentColorOption.color(accentColor))
        }
    }
}
