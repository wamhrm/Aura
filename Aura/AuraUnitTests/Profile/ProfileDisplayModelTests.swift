//
//  ProfileDisplayModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class ProfileDisplayModelTests: XCTestCase {
    func test_make_withoutDailyTip_usesPlaceholder() {
        // Given / When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil)

        // Then
        XCTAssertFalse(result.dailyTip.isEmpty)
    }

    func test_make_withDailyTip_usesProvidedText() {
        // Given
        let tip = DailyContentModel(id: UUID(), text: "Мой совет дня", dateCreated: "2026-01-01")

        // When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: tip)

        // Then
        XCTAssertEqual(result.dailyTip, "Мой совет дня")
    }
}
