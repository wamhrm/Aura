//
//  UserModel.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import Foundation

struct UserModel: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let email: String?
    let dateOfBirth: String?
    let birthTime: String?
    let gender: String?
    let socialType: String?
    let conflictStyle: String?
    let emotionalCore: String?
    let decisionStyle: String?
    let coreFocus: String?
    var hasAIConsent: Bool?
    let isEmailConfirmed: Bool?
    
    var nameCapitalized: String {
        name.capitalized
    }

    var nameInitials: String {
        name.prefix(2).uppercased()
    }

    var birthDate: Date? {
        dateOfBirth.flatMap(BirthDateFormatter.date(string:))
    }

    var zodiacSign: HoroscopeTypes? {
        guard let birthDate else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: birthDate)
        let month = calendar.component(.month, from: birthDate)

        switch (month, day) {
            case (1, 20...31), (2, 1...18): return .aquarius
            case (2, 19...29), (3, 1...20): return .pisces
            case (3, 21...31), (4, 1...19): return .aries
            case (4, 20...30), (5, 1...20): return .taurus
            case (5, 21...31), (6, 1...20): return .gemini
            case (6, 21...30), (7, 1...22): return .cancer
            case (7, 23...31), (8, 1...22): return .leo
            case (8, 23...31), (9, 1...22): return .virgo
            case (9, 23...30), (10, 1...22): return .libra
            case (10, 23...31), (11, 1...21): return .scorpio
            case (11, 22...30), (12, 1...21): return .sagittarius
            case (12, 22...31), (1, 1...19): return .capricorn
            default: return nil
        }
    }

    var hasCompletedProfileInfo: Bool {
        dateOfBirth != nil && profileInfo.hasAllAnswers
    }

    var allowsAIAnalysis: Bool {
        hasAIConsent == true
    }

    var hasConfirmedEmail: Bool {
        isEmailConfirmed == true
    }
    
    var profileInfo: ProfileInfoModel {
        ProfileInfoModel(user: self)
    }
}

extension UserModel {
    static let mock = UserModel(id: UUID(),
                                name: "Дмитрий",
                                email: "test@test.com",
                                dateOfBirth: "13.05.2000",
                                birthTime: "12:00",
                                gender: "man",
                                socialType: "introvert",
                                conflictStyle: "mediator",
                                emotionalCore: "logic",
                                decisionStyle: "planner",
                                coreFocus: "stability",
                                hasAIConsent: true,
                                isEmailConfirmed: true)
}
