//
//  ProfileInfoModel.swift
//  Aura
//
//  Created by wamhrm on 05.05.2026.
//

import Foundation

struct ProfileInfoModel: Codable {
    var dateOfBirth = ""
    var birthTime = ""
    var gender: String?
    var socialType: String?
    var conflictStyle: String?
    var emotionalCore: String?
    var decisionStyle: String?
    var coreFocus: String?
    
    init() { }

    var hasAllAnswers: Bool {
        gender != nil &&
        socialType != nil &&
        conflictStyle != nil &&
        emotionalCore != nil &&
        decisionStyle != nil &&
        coreFocus != nil
    }
    
    init(user: UserModel) {
        self.dateOfBirth = user.dateOfBirth ?? ""
        self.birthTime = user.birthTime ?? ""
        self.gender = user.gender
        self.socialType = user.socialType
        self.conflictStyle = user.conflictStyle
        self.emotionalCore = user.emotionalCore
        self.decisionStyle = user.decisionStyle
        self.coreFocus = user.coreFocus
    }
}

