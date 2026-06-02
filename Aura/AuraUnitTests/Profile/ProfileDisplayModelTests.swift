//
//  ProfileDisplayModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

final class ProfileDisplayModelTests: XCTestCase {
    func test_make_withoutDailyTip_usesPlaceholder() {
        // Given / When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil, history: [])

        // Then
        XCTAssertFalse(result.dailyTip.isEmpty)
    }

    func test_make_withDailyTip_usesProvidedText() {
        // Given
        let tip = DailyContentModel(id: UUID(), text: "Мой совет дня", dateCreated: "2026-01-01")

        // When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: tip, history: [])

        // Then
        XCTAssertEqual(result.dailyTip, "Мой совет дня")
    }

    func test_make_withEmptyHistory_hasNoBestCompatibility() {
        // Given / When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil, history: [])

        // Then
        XCTAssertNil(result.bestCompatibility)
    }

    func test_make_withCompatibilityHistory_setsBestCompatibility() {
        // Given
        let history = [HistoryCellModel.compatibilityPlaceholder]

        // When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil, history: history)

        // Then
        XCTAssertEqual(result.bestCompatibility?.score, CompabilityResultModel.mock.compatibilityScore)
        XCTAssertEqual(result.bestCompatibility?.partnerName, CompabilityResultModel.mock.partnerNameCapitalized)
    }

    func test_make_withPersonalityHistoryOnly_hasNoBestCompatibility() {
        // Given
        let history = [HistoryCellModel.personalityPlaceholder]

        // When
        let result = ProfileDisplayModel.make(personalityResult: nil, dailyTip: nil, history: history)

        // Then
        XCTAssertNil(result.bestCompatibility)
    }
}
