//
//  HomeViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class HomeViewModelTests: XCTestCase {
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
        XCTAssertEqual(sut.alertMessage, "Нельзя выбрать меньше 2 тестов")
        XCTAssertEqual(sut.selectedTests, initialSelection)
    }

    func test_toggleTestSelection_addsUnselectedTest() throws {
        // Given
        let (sut, _, _) = makeSUT()
        let testToAdd = try XCTUnwrap(PersonalityTestTypes.allCases.first { !sut.selectedTests.contains($0) })

        // When
        sut.toggleTestSelection(testToAdd)

        // Then
        XCTAssertTrue(sut.selectedTests.contains(testToAdd))
    }

    func test_toggleTestSelection_removesWhenAboveMinimum() throws {
        // Given
        let (sut, _, _) = makeSUT()
        let extraTest = try XCTUnwrap(PersonalityTestTypes.allCases.first { !sut.selectedTests.contains($0) })
        sut.toggleTestSelection(extraTest)
        let testToRemove = sut.selectedTests[0]

        // When
        sut.toggleTestSelection(testToRemove)

        // Then
        XCTAssertFalse(sut.selectedTests.contains(testToRemove))
        XCTAssertEqual(sut.selectedTests.count, 2)
    }

    // MARK: - Personality test
    func test_makePersonalityTest_whenSucceeds_setsResultAndAppendsRoute() async {
        // Given
        let (sut, _, content) = makeSUT()

        // When
        sut.makePersonalityTest()
        await waitUntil { sut.personalityResult != nil }

        // Then
        XCTAssertEqual(content.makePersonalityTestCallCount, 1)
        XCTAssertTrue(sut.homeRoutes.contains(.testResults))
        XCTAssertFalse(sut.isLoading)
    }

    func test_makePersonalityTest_whenServiceFails_showsAlert() async {
        // Given
        let (sut, _, content) = makeSUT()
        content.errorToThrow = MockError.notStubbed

        // When
        sut.makePersonalityTest()
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Не удалось получить результат")
        XCTAssertFalse(sut.homeRoutes.contains(.testResults))
    }

    // MARK: - saveProfileInfo
    func test_saveProfileInfo_whenDateInvalid_showsAlertAndDoesNotProceed() async {
        // Given
        let (sut, _, _) = makeSUT(authState: .signedIn(makeIncompleteUser()))
        await waitUntil { sut.isSignedIn }
        // profileInfo.dateOfBirth == "" (длина != 10)

        // When
        sut.saveProfileInfo {}
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Укажите дату рождения в формате ДД.ММ.ГГГГ")
        XCTAssertFalse(sut.hasProfileInfo)
    }

    func test_saveProfileInfo_whenProfileIncomplete_showsAlertAndDoesNotProceed() async {
        // Given
        let (sut, _, _) = makeSUT(authState: .signedIn(makeIncompleteUser()))
        await waitUntil { sut.isSignedIn }
        sut.profileInfo.dateOfBirth = "01.01.2000"
        // остальные поля nil

        // When
        sut.saveProfileInfo {}
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Заполните все обязательные поля профиля")
        XCTAssertFalse(sut.hasProfileInfo)
    }

    func test_saveProfileInfo_whenValid_callsServiceAndUpdatesState() async {
        // Given
        let (sut, auth, _) = makeSUT(authState: .signedIn(makeIncompleteUser()))
        await waitUntil { sut.isSignedIn }
        auth.updateProfileInfoResult = UpdateProfileInfoResponse(user: .mock, horoscope: .mock)
        fillValidProfileInfo(sut)

        // When
        sut.saveProfileInfo {}
        await waitUntil { sut.hasProfileInfo }

        // Then
        XCTAssertTrue(sut.hasProfileInfo)
        XCTAssertFalse(sut.showAlert)
    }
    
    // MARK: - Helpers
    private func makeSUT(authState: AuthState = .signedOut)
        -> (sut: HomeViewModel, auth: MockAuthService, content: MockContentService) {
        let auth = MockAuthService(state: authState)
        let content = MockContentService()
        let sut = HomeViewModel(authService: auth, contentService: content)
        return (sut, auth, content)
    }

    private func fillValidProfileInfo(_ sut: HomeViewModel) {
        sut.profileInfo.dateOfBirth = "01.01.2000"
        sut.profileInfo.gender = "man"
        sut.profileInfo.socialType = "introvert"
        sut.profileInfo.conflictStyle = "mediator"
        sut.profileInfo.emotionalCore = "logic"
        sut.profileInfo.decisionStyle = "planner"
        sut.profileInfo.coreFocus = "stability"
    }
}
