//
//  ProfileViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import SwiftUI
import Combine

enum ProfileRoutes: Hashable {
    case completeProfile, settings
}

final class ProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    
    @Published var profileRoutes: [ProfileRoutes] = []
    @Published private(set) var authState = AuthState.signedOut
    @Published var showSettings = false
    
    var isProfileCompleted: Bool {
        return false
    }
}
