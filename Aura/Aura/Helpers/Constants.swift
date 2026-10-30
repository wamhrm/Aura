//
//  Constants.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import Foundation

nonisolated enum Constants {
    static let productionBaseURL = "https://aura-mogr.onrender.com"
    static let tokenPath = "com.aura.auth.token"

    static var baseURL: String {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["AURA_BASE_URL"], !override.isEmpty {
            return override
        }
        #endif
        return productionBaseURL
    }

    static var privacyPolicyURL: URL? {
        URL(string: baseURL + "/privacy.html")
    }

    static var termsOfUseURL: URL? {
        URL(string: baseURL + "/terms.html")
    }
    
    static let userKey = "userKey"
    static let tokenKey = "tokenKey"
    
    static let horoscopeKeyPrefix = "horoscopeKey_"
    static let personalityKeyPrefix = "personalityKey_"
    static let historyKeyPrefix = "historyKey_"
    static let dailyInsightKeyPrefix = "dailyInsightKey_"
    static let dailyTipKeyPrefix = "dailyTipKey_"
    
    static let selectedThemeKey = "selectedTheme"
    static let accentColorKey = "accentColor"
}
