//
//  AuthDTOs.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Vapor

struct CreateAccountRequest: Content {
    let name: String
    let email: String
    let password: String
}

struct SignInRequest: Content {
    let email: String
    let password: String
}

struct UserDTO: Content {
    let id: UUID
    let name: String
    let email: String
    let dateOfBirth: String?
    let birthTime: String?
    let gender: String?
    let socialType: String?
    let conflictStyle: String?
    let emotionalCore: String?
    let decisionStyle: String?
    let coreFocus: String?
}

struct AuthDTO: Content {
    let token: String
    let user: UserDTO
}

struct UpdateProfileInfoResponse: Content {
    let user: UserDTO
    let horoscope: HoroscopeDTO
}

struct UpdateProfileInfoRequest: Content {
    let dateOfBirth: String
    let birthTime: String?
    let gender: String
    let socialType: String
    let conflictStyle: String
    let emotionalCore: String
    let decisionStyle: String
    let coreFocus: String
}

enum InputLimits {
    static let minNameLength = 2
    static let maxNameLength = 50
    static let maxEmailLength = 254
    static let minPasswordLength = 6
    static let maxPasswordBytes = 72
}

enum ProfileInfoOptions {
    static let genders: Set<String> = ["man", "woman"]
    static let socialTypes: Set<String> = ["introvert", "ambivert", "extrovert"]
    static let conflictStyles: Set<String> = ["mediator", "direct", "avoider"]
    static let emotionalCores: Set<String> = ["logic", "intuitive"]
    static let decisionStyles: Set<String> = ["planner", "spontaneous", "procrastinator"]
    static let coreFocuses: Set<String> = ["stability", "growth", "peace"]
}
