//
//  Constants.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import Foundation

nonisolated enum Constants {
    static let userKey = "userKey"
    static let tokenKey = "tokenKey"

    static let selectedThemeKey = "selectedTheme"
    static let accentColorKey = "accentColor"
    
    private static let productionBaseURL = "https://aurawamhrm.space"
    static let apiPath = "/v1"
    
    static var uiTestID: String? {
        guard let value = ProcessInfo.processInfo.environment["AURA_UI_TEST_ID"],
              let id = UUID(uuidString: value) else { return nil }
        return id.uuidString
    }

    static var tokenPath: String {
        guard let uiTestID else { return "com.aura.auth.token" }
        return "com.aura.auth.token.ui-tests.\(uiTestID)"
    }

    static var userDefaults: UserDefaults {
        guard let uiTestID else { return .standard }
        return UserDefaults(suiteName: "com.aura.ui-tests.\(uiTestID)") ?? .standard
    }

    static var baseURL: String {
        if uiTestID != nil,
           let override = ProcessInfo.processInfo.environment["AURA_BASE_URL"], !override.isEmpty {
            return override
        }
        return productionBaseURL
    }

    static var privacyPolicyURL: URL? {
        URL(string: baseURL + "/privacy.html")
    }

    static var termsOfUseURL: URL? {
        URL(string: baseURL + "/terms.html")
    }
}

nonisolated enum InputLimits {
    static let minNameLength = 2
    static let maxNameLength = 50
    static let minPasswordLength = 8
    static let resetCodeLength = 6
    static let minUserAge = 16
    static let adultAge = 18
    static let maxUserAge = 100
    static let minPersonalityTests = 2
    static let minCompatibilityTests = 3
}
