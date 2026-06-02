//
//  UserModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

final class UserModelTests: XCTestCase {
    func test_hasCompletedProfileInfo_whenAllFieldsPresent_returnsTrue() {
        // Given
        let user = UserModel.mock

        // When
        let result = user.hasCompletedProfileInfo

        // Then
        XCTAssertTrue(result)
    }

    func test_hasCompletedProfileInfo_whenOneFieldMissing_returnsFalse() {
        // Given
        let user = UserModel(id: UUID(),
                             name: "Test",
                             email: "test@test.com",
                             dateOfBirth: "13.05.2000",
                             birthTime: "12:00",
                             gender: "man",
                             socialType: "introvert",
                             conflictStyle: "mediator",
                             emotionalCore: "logic",
                             decisionStyle: "planner",
                             coreFocus: nil)

        // When
        let result = user.hasCompletedProfileInfo

        // Then
        XCTAssertFalse(result)
    }
}
