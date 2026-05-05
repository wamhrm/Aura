//
//  UserModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation

struct UserModel {
    let id: UUID
    let name: String
    let email: String
    let dateOfBirth: Date
    
    static let mock = UserModel(id: UUID(), name: "Дмитрий", email: "test@test.com", dateOfBirth: .now)
}
