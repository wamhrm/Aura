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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authService)
        }
    }
}
