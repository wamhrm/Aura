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
    @StateObject private var psychologyService = PsychologyService()

    var body: some Scene {
        WindowGroup {
            MainTabView(authService: authService,
                        psychologyService: psychologyService)
        }
    }
}
