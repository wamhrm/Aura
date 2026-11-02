//
//  ProfileDisplayModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class ProfileDisplayModelTests: XCTestCase {
    func test_make_withoutData_inventsNothing() {
        // Given / When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil)

        // Then
        XCTAssertNil(result.dailyTip)
        XCTAssertNil(result.overview)
        XCTAssertNil(result.socialFilter)
        XCTAssertNil(result.temperament)
        XCTAssertFalse(result.hasTopics)
    }

    func test_make_whenTestDidNotProduceTheItem_leavesItEmpty() {
        // Given: the mock result has no "behavioral patterns" or "ideal partner" sections
        let result = PersonalityResultModel.mock

        // When
        let display = ProfileDisplayModel.make(personalityResult: result, dailyTip: nil)

        // Then
        XCTAssertEqual(display.overview, result.overview.description)
        XCTAssertNil(display.socialFilter)
        XCTAssertNil(display.emotionalDepth)
        XCTAssertEqual(display.temperament, 7)
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
