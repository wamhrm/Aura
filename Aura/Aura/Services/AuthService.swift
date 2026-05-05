//
//  AuthService.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import Combine

enum AuthState {
    case signedIn(UserModel)
    case signedOut
}

protocol AuthServiceProtocol {
    var authState: CurrentValueSubject<AuthState, Never> { get }
}

final class AuthService: AuthServiceProtocol {
    var authState = CurrentValueSubject<AuthState, Never>(.signedOut)
}
