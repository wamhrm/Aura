//
//  TestSupport.swift
//  AuraUnitTests
//

import Foundation
import XCTest
@testable import Aura

@MainActor
func waitUntil(timeout: TimeInterval = 3,
               file: StaticString = #filePath,
               line: UInt = #line,
               _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() >= deadline {
            XCTFail("The condition was not met in \(timeout) seconds", file: file, line: line)
            break
        }
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
              coreFocus: nil,
              hasAIConsent: nil)
}
