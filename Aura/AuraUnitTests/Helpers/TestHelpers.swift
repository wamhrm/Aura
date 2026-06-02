//
//  TestSupport.swift
//  AuraUnitTests
//

import Foundation
@testable import Aura

@MainActor
func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() >= deadline { break }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

func makeIncompleteUser() -> UserModel {
    UserModel(id: UUID(),
              name: "Test",
              email: "test@test.com",
              dateOfBirth: nil,
              birthTime: nil,
              gender: nil,
              socialType: nil,
              conflictStyle: nil,
              emotionalCore: nil,
              decisionStyle: nil,
              coreFocus: nil)
}
