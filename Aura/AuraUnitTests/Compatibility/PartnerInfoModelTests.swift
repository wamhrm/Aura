//
//  PartnerInfoModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

final class PartnerInfoModelTests: XCTestCase {
    func test_compatibilityTestRequest_withExactDate_mapsDateAndTimeAndTrimsName() {
        // Given
        var info = PartnerInfoModel()
        info.name = "  Анна  "
        info.gender = "Женский"
        info.exactDateOfBirth = true
        info.dateOfBirth = "01.01.2000"
        info.birthTime = "12:00"
        info.age = "25"

        // When
        let request = info.compatibilityTestRequest(selectedTests: [.astrology])

        // Then
        XCTAssertEqual(request.partnerName, "Анна")
        XCTAssertEqual(request.partnerDateOfBirth, "01.01.2000")
        XCTAssertEqual(request.partnerBirthTime, "12:00")
        XCTAssertNil(request.partnerAge)
        XCTAssertEqual(request.partnerGender, "Женский")
        XCTAssertTrue(request.exactDateOfBirth)
        XCTAssertEqual(request.selectedTests, [CompatibilityTestTypes.astrology.rawValue])
    }

    func test_compatibilityTestRequest_withApproximateDate_mapsAgeAndNilsDate() {
        // Given
        var info = PartnerInfoModel()
        info.name = "Иван"
        info.exactDateOfBirth = false
        info.dateOfBirth = "01.01.2000"
        info.birthTime = "12:00"
        info.age = "30"

        // When
        let request = info.compatibilityTestRequest(selectedTests: [])

        // Then
        XCTAssertNil(request.partnerDateOfBirth)
        XCTAssertNil(request.partnerBirthTime)
        XCTAssertEqual(request.partnerAge, "30")
        XCTAssertFalse(request.exactDateOfBirth)
    }

    func test_compatibilityTestRequest_withExactDateButBlankValues_setsNil() {
        // Given
        var info = PartnerInfoModel()
        info.name = "Тест"
        info.exactDateOfBirth = true
        info.dateOfBirth = "   "
        info.birthTime = ""

        // When
        let request = info.compatibilityTestRequest(selectedTests: [])

        // Then
        XCTAssertNil(request.partnerDateOfBirth)
        XCTAssertNil(request.partnerBirthTime)
    }
}
