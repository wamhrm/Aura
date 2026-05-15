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
    @StateObject private var personalityService = PersonalityService()

    var body: some Scene {
        WindowGroup {
            MainTabView(authService: authService,
                        personalityService: personalityService)
        }
    }
}
