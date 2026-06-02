//
//  CompatibilityViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class CompatibilityViewModelTests: XCTestCase {
    // MARK: - Guards
    func test_makeCompatibilityTest_whenSignedOut_showsSignInAlertAndDoesNotCallService() {
        // Given
        let (sut, _, content) = makeSUT(authState: .signedOut)

        // When
        sut.makeCompatibilityTest()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Войдите или зарегистрируйтесь")
        XCTAssertEqual(content.makeCompatibilityTestCallCount, 0)
    }

    func test_makeCompatibilityTest_whenProfileIncomplete_showsCompleteProfileAlertAndDoesNotCallService() {
        // Given
        let (sut, _, content) = makeSUT(authState: .signedIn(makeIncompleteUser()))

        // When
        sut.makeCompatibilityTest()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Заполните информацию о себе")
        XCTAssertEqual(content.makeCompatibilityTestCallCount, 0)
    }

    // MARK: - Success

    func test_makeCompatibilityTest_whenValid_callsServiceAndAppendsResultRoute() async {
        // Given
        let (sut, _, content) = makeSUT(authState: .signedIn(.mock))
        fillValidPartnerInfo(sut)

        // When
        sut.makeCompatibilityTest()
        await waitUntil { sut.compatibilityResult != nil }

        // Then
        XCTAssertEqual(content.makeCompatibilityTestCallCount, 1)
        XCTAssertTrue(sut.compatibilityRoutes.contains(.compatibilityResults))
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showAlert)
    }

    // MARK: - Validation failures (выполняются внутри Task)
    func test_makeCompatibilityTest_whenNameTooShort_showsValidationAlert() async {
        // Given
        let (sut, _, _) = makeSUT(authState: .signedIn(.mock))
        sut.partnerInfo.name = "A"
        sut.partnerInfo.exactDateOfBirth = true
        sut.partnerInfo.dateOfBirth = "01.01.2000"

        // When
        sut.makeCompatibilityTest()
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Имя партнёра должно содержать минимум 2 символа")
    }

    func test_makeCompatibilityTest_whenExactDateInvalid_showsValidationAlert() async {
        // Given
        let (sut, _, _) = makeSUT(authState: .signedIn(.mock))
        sut.partnerInfo.name = "Анна"
        sut.partnerInfo.exactDateOfBirth = true
        sut.partnerInfo.dateOfBirth = "01.01"

        // When
        sut.makeCompatibilityTest()
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Укажите дату рождения в формате ДД.ММ.ГГГГ")
    }

    func test_makeCompatibilityTest_whenApproximateAgeInvalid_showsValidationAlert() async {
        // Given
        let (sut, _, _) = makeSUT(authState: .signedIn(.mock))
        sut.partnerInfo.name = "Анна"
        sut.partnerInfo.exactDateOfBirth = false
        sut.partnerInfo.age = "abc"

        // When
        sut.makeCompatibilityTest()
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Укажите возраст партнёра")
    }

    // MARK: - Test selection
    func test_toggleTestSelection_whenRemovingBelowMinimum_showsAlertAndKeepsSelection() {
        // Given
        let (sut, _, _) = makeSUT()
        let initialSelection = sut.selectedTests
        let testToRemove = initialSelection[0]

        // When
        sut.toggleTestSelection(testToRemove)

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Нельзя выбрать меньше 3 тестов")
        XCTAssertEqual(sut.selectedTests, initialSelection)
    }

    func test_toggleTestSelection_addsUnselectedTest() throws {
        // Given
        let (sut, _, _) = makeSUT()
        let testToAdd = try XCTUnwrap(CompatibilityTestTypes.allCases.first { !sut.selectedTests.contains($0) })

        // When
        sut.toggleTestSelection(testToAdd)

        // Then
        XCTAssertTrue(sut.selectedTests.contains(testToAdd))
    }

    func test_toggleTestSelection_removesWhenAboveMinimum() throws {
        // Given
        let (sut, _, _) = makeSUT()
        let extraTest = try XCTUnwrap(CompatibilityTestTypes.allCases.first { !sut.selectedTests.contains($0) })
        sut.toggleTestSelection(extraTest)
        let testToRemove = sut.selectedTests[0]

        // When
        sut.toggleTestSelection(testToRemove)

        // Then
        XCTAssertFalse(sut.selectedTests.contains(testToRemove))
        XCTAssertEqual(sut.selectedTests.count, 3)
    }

    // MARK: - clearFields
    func test_clearFields_resetsEnteredTextFieldsOnly() {
        // Given
        let (sut, _, _) = makeSUT()
        sut.partnerInfo.name = "Анна"
        sut.partnerInfo.dateOfBirth = "01.01.2000"
        sut.partnerInfo.birthTime = "12:00"
        sut.partnerInfo.age = "25"
        sut.partnerInfo.gender = "Женский"
        sut.partnerInfo.exactDateOfBirth = false

        // When
        sut.clearFields()

        // Then
        XCTAssertEqual(sut.partnerInfo.name, "")
        XCTAssertEqual(sut.partnerInfo.dateOfBirth, "")
        XCTAssertEqual(sut.partnerInfo.birthTime, "")
        XCTAssertEqual(sut.partnerInfo.age, "")
        XCTAssertEqual(sut.partnerInfo.gender, "Женский")
        XCTAssertFalse(sut.partnerInfo.exactDateOfBirth)
    }
    
    // MARK: - Helpers
    private func makeSUT(authState: AuthState = .signedOut)
        -> (sut: CompatibilityViewModel, auth: MockAuthService, content: MockContentService) {
        let auth = MockAuthService(state: authState)
        let content = MockContentService()
        let sut = CompatibilityViewModel(authService: auth, contentService: content)
        return (sut, auth, content)
    }

    private func fillValidPartnerInfo(_ sut: CompatibilityViewModel) {
        sut.partnerInfo.name = "Анна"
        sut.partnerInfo.exactDateOfBirth = true
        sut.partnerInfo.dateOfBirth = "01.01.2000"
    }
}
