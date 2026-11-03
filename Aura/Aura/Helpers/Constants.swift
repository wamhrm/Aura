//
//  Constants.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import Foundation

nonisolated enum Constants {
    static let productionBaseURL = "https://aurawamhrm.space"
    static let apiPath = "/v1"
    static let tokenPath = "com.aura.auth.token"

    static var baseURL: String {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["AURA_BASE_URL"], !override.isEmpty {
            return override
        }
        #endif
        return productionBaseURL
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    static var privacyPolicyURL: URL? {
        URL(string: baseURL + "/privacy.html")
    }

    static var termsOfUseURL: URL? {
        URL(string: baseURL + "/terms.html")
    }
    
    static let tokenKey = "tokenKey"

    static let selectedThemeKey = "selectedTheme"
    static let accentColorKey = "accentColor"
}

// Copies of the server rules for instant feedback
nonisolated enum InputLimits {
    static let minNameLength = 2
    static let maxNameLength = 50
    static let minPasswordLength = 8
    static let resetCodeLength = 6
    static let minUserAge = 16
    static let maxUserAge = 100
    static let minPersonalityTests = 2
    static let minCompatibilityTests = 3
}
