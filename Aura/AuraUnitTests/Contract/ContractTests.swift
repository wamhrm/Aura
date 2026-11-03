//
//  ContractTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest
@testable import Aura

// The Contract folder is shared with the backend tests. A change on one side fails until both sides agree.
@MainActor
final class ContractTests: XCTestCase {
    private struct Keys: Decodable {
        struct Limits: Decodable {
            let minNameLength: Int
            let minPasswordLength: Int
            let resetCodeLength: Int
            let minUserAge: Int
            let maxUserAge: Int
            let minPartnerAge: Int
            let maxPartnerAge: Int
            let minPersonalityTests: Int
            let minCompatibilityTests: Int
        }

        let personalityTests: [String: [String]]
        let compatibilityTests: [String: [String]]
        let personalityBars: [String]
        let compatibilityBars: [String]
        let zodiacSigns: [String]
        let horoscopeItems: [String]
        let profileOptions: [String: [String]]
        let limits: Limits
    }

    private func contractData(_ name: String) throws -> Data {
        let folder = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Contract")

        return try Data(contentsOf: folder.appendingPathComponent(name))
    }

    private func loadKeys() throws -> Keys {
        try JSONDecoder().decode(Keys.self, from: try contractData("keys.json"))
    }

    private func decodeContract<T: Decodable>(_ type: T.Type, from name: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: try contractData(name))
    }

    // MARK: - Keys and limits
    func test_tests_matchTheContract() throws {
        // Given
        let keys = try loadKeys()

        // When
        let personalityItems = Set(keys.personalityTests.values.flatMap { $0 })
        let compatibilityItems = Set(keys.compatibilityTests.values.flatMap { $0 })

        // Then
        XCTAssertEqual(Set(PersonalityTestTypes.allCases.map(\.rawValue)), Set(keys.personalityTests.keys))
        XCTAssertEqual(Set(CompatibilityTestTypes.allCases.map(\.rawValue)), Set(keys.compatibilityTests.keys))
        XCTAssertEqual(Set(PersonalityCellTypes.allCases.map(\.rawValue)), personalityItems)
        XCTAssertEqual(Set(CompatibilityCellTypes.allCases.map(\.rawValue)), compatibilityItems)
    }

    func test_otherKeys_matchTheContract() throws {
        // Given
        let keys = try loadKeys()

        // When
        let bars = Set(keys.personalityBars + keys.compatibilityBars)
        let profileOptions = Set(keys.profileOptions.values.flatMap { $0 })

        // Then
        XCTAssertEqual(Set(EmotionalProfileTypes.allCases.map(\.rawValue)), bars)
        XCTAssertEqual(HoroscopeTypes.allCases.map(\.rawValue), keys.zodiacSigns)
        XCTAssertEqual(HoroscopeDetailsCellTypes.allCases.map(\.rawValue), keys.horoscopeItems)
        XCTAssertEqual(Set(ProfileInfoOption.allCases.map(\.rawValue)), profileOptions)
        XCTAssertEqual(CompatibilityButtons.genderOptions.allCases.map(\.key), keys.profileOptions["gender"])
    }

    func test_limits_matchTheContract() throws {
        // Given
        let limits = try loadKeys().limits

        // When / Then
        XCTAssertEqual(InputLimits.minNameLength, limits.minNameLength)
        XCTAssertEqual(InputLimits.minPasswordLength, limits.minPasswordLength)
        XCTAssertEqual(InputLimits.resetCodeLength, limits.resetCodeLength)
        XCTAssertEqual(InputLimits.minUserAge, limits.minUserAge)
        XCTAssertEqual(InputLimits.maxUserAge, limits.maxUserAge)
        XCTAssertEqual(InputLimits.minPartnerAge, limits.minPartnerAge)
        XCTAssertEqual(InputLimits.maxPartnerAge, limits.maxPartnerAge)
        XCTAssertEqual(InputLimits.minPersonalityTests, limits.minPersonalityTests)
        XCTAssertEqual(InputLimits.minCompatibilityTests, limits.minCompatibilityTests)
    }

    // MARK: - Responses
    func test_responses_decodeIntoTheModels() throws {
        // When
        let auth = try decodeContract(AuthTokenResponse.self, from: "auth.json")
        let horoscope = try decodeContract(HoroscopeModel.self, from: "horoscope.json")
        let personality = try decodeContract(PersonalityResultModel.self, from: "personality_result.json")
        let compatibility = try decodeContract(CompabilityResultModel.self, from: "compatibility_result.json")
        let history = try decodeContract([HistoryCellModel].self, from: "history_list.json")
        let daily = try decodeContract(DailyContentModel.self, from: "daily.json")

        // Then
        XCTAssertEqual(auth.user.gender, ProfileInfoOption.woman.rawValue)
        XCTAssertTrue(auth.user.hasConfirmedEmail)
        XCTAssertEqual(horoscope.type, .taurus)
        XCTAssertEqual(horoscope.items.map(\.key), [.love, .health, .work])
        XCTAssertEqual(personality.zodiacSign, .taurus)
        XCTAssertEqual(personality.sections.first?.selectedTest, .astrology)
        XCTAssertEqual(personality.emotionalBar.first?.key, .temperament)
        XCTAssertEqual(compatibility.partnerZodiacSign, .aquarius)
        XCTAssertEqual(compatibility.sections.first?.items.first?.key, .synastry)
        XCTAssertEqual(history.map(\.kind), [.compatibility, .personality])
        XCTAssertNil(history.last?.partnerZodiacSign)
        XCTAssertFalse(daily.text.isEmpty)
    }
}
