//
//  AuraApp.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

@main
enum AuraEntryPoint {
    static func main() {
        #if DEBUG
        // Unit tests run inside the app process, the real app must not start and reach the server
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            UnitTestHostApp.main()
            return
        }
        #endif

        AuraApp.main()
    }
}

#if DEBUG
private struct UnitTestHostApp: App {
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}
#endif

struct AuraApp: App {
    @StateObject private var authService: AuthService
    @StateObject private var contentService: ContentService

    @AppStorage(Constants.selectedThemeKey) private var selectedTheme = AppTheme.light
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

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
