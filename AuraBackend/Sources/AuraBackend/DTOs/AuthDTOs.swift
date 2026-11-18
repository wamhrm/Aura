//
//  AuthDTOs.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
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

struct ForgotPasswordRequest: Content {
    let email: String
}

struct EmailAvailabilityRequest: Content {
    let email: String
}

struct ResetPasswordRequest: Content {
    let email: String
    let code: String
    let password: String
}

struct ConfirmEmailRequest: Content {
    let code: String
}

struct UserDTO: Content {
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
    let hasAIConsent: Bool
    let isEmailConfirmed: Bool
}

struct AuthDTO: Content {
    let token: String
    let user: UserDTO
}

struct UpdateProfileInfoResponse: Content {
    let user: UserDTO
}

struct UpdateProfileInfoRequest: Content {
    var name: String? = nil
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
    static let minPasswordLength = 8
    static let maxPasswordBytes = 72
}
