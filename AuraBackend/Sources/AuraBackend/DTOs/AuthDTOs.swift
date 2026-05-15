import Vapor
import Foundation

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
