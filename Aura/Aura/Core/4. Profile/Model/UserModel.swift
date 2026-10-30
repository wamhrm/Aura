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
    let hasAIConsent: Bool?
    
    var nameCapitalized: String {
        name.capitalized
    }

    var nameInitials: String {
        name.prefix(2).uppercased()
    }

    var dateOfBirthHandler: String {
        dateOfBirth ?? "Дата рождения не указана"
    }

    var hasCompletedProfileInfo: Bool {
        dateOfBirth != nil &&
        gender != nil &&
        socialType != nil &&
        conflictStyle != nil &&
        emotionalCore != nil &&
        decisionStyle != nil &&
        coreFocus != nil
    }

    var allowsAIAnalysis: Bool {
        hasAIConsent == true
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
                                hasAIConsent: true)
}
