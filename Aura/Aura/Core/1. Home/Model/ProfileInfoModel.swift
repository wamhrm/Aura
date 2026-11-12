//
//  ProfileInfoModel.swift
//  Aura
//
//  Created by wamhrm on 05.05.2026.
//

import Foundation

struct ProfileInfoModel: Codable, Equatable {
    var name: String?
    var dateOfBirth = ""
    var birthTime = ""
    var socialType: String?
    var conflictStyle: String?
    var emotionalCore: String?
    var decisionStyle: String?
    var coreFocus: String?
    
    init() { }

    var hasAllAnswers: Bool {
        socialType != nil &&
        conflictStyle != nil &&
        emotionalCore != nil &&
        decisionStyle != nil &&
        coreFocus != nil
    }
    
    init(user: UserModel) {
        self.dateOfBirth = user.dateOfBirth ?? ""
        self.birthTime = user.birthTime ?? ""
        self.socialType = user.socialType
        self.conflictStyle = user.conflictStyle
        self.emotionalCore = user.emotionalCore
        self.decisionStyle = user.decisionStyle
        self.coreFocus = user.coreFocus
    }
}

