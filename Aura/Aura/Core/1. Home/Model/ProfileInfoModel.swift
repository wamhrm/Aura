//
//  ProfileInfoModel.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
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
    
    init(user: UserModel) {
        self.dateOfBirth = user.dateOfBirth ?? ""
        self.birthTime = user.birthTime ?? ""
        self.gender = ProfileInfoOption.normalizedKey(user.gender)
        self.socialType = ProfileInfoOption.normalizedKey(user.socialType)
        self.conflictStyle = ProfileInfoOption.normalizedKey(user.conflictStyle)
        self.emotionalCore = ProfileInfoOption.normalizedKey(user.emotionalCore)
        self.decisionStyle = ProfileInfoOption.normalizedKey(user.decisionStyle)
        self.coreFocus = ProfileInfoOption.normalizedKey(user.coreFocus)
    }
}

