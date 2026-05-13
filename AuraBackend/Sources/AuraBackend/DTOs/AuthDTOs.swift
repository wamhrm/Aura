import Vapor
import Foundation

struct RegisterUserRequest: Content {
    let name: String
    let email: String
    let password: String
}

struct LoginUserRequest: Content {
    let email: String
    let password: String
}

struct UserResponse: Content {
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

struct AuthResponse: Content {
    let token: String
    let user: UserResponse
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
