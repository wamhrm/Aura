//
//  ProfileFormViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class ProfileFormViewModelTests: XCTestCase {
    func test_init_fillsTheFormFromTheUser() {
        // Given / When
        let (sut, _) = makeSUT(user: .mock)

        // Then
        XCTAssertEqual(sut.profileInfo.dateOfBirth, UserModel.mock.dateOfBirth)
        XCTAssertEqual(sut.profileInfo.gender, UserModel.mock.gender)
    }

    func test_saveProfileInfo_whenDateInvalid_showsAlertAndDoesNotProceed() async {
        // Given
        let (sut, auth) = makeSUT(user: makeIncompleteUser())

        // When
        sut.saveProfileInfo {}
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Укажите дату рождения в формате ДД.ММ.ГГГГ")
        XCTAssertEqual(auth.updateProfileInfoCallCount, 0)
    }

    func test_saveProfileInfo_whenProfileIncomplete_showsAlertAndDoesNotProceed() async {
        // Given
        let (sut, auth) = makeSUT(user: makeIncompleteUser())
        sut.profileInfo.dateOfBirth = "01.01.2000"

        // When
        sut.saveProfileInfo {}
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertEqual(sut.alertMessage, "Заполните все обязательные поля профиля")
        XCTAssertEqual(auth.updateProfileInfoCallCount, 0)
    }

    func test_saveProfileInfo_whenValid_callsServiceAndFinishes() async {
        // Given
        let (sut, auth) = makeSUT(user: .mock)
        auth.updateProfileInfoResult = UpdateProfileInfoResponse(user: .mock, horoscope: .mock)
        var didSave = false

        // When
        sut.saveProfileInfo { didSave = true }
        await waitUntil { didSave }

        // Then
        XCTAssertEqual(auth.updateProfileInfoCallCount, 1)
        XCTAssertFalse(sut.showAlert)
    }

    func test_saveProfileInfo_whenServiceFails_showsAlertAndDoesNotFinish() async {
        // Given
        let (sut, auth) = makeSUT(user: .mock)
        auth.errorToThrow = MockError.notStubbed
        var didSave = false

        // When
        sut.saveProfileInfo { didSave = true }
        await waitUntil { sut.showAlert }

        // Then
        XCTAssertFalse(didSave)
    }

    // MARK: - Helpers
    private func makeSUT(user: UserModel) -> (sut: ProfileFormViewModel, auth: MockAuthService) {
        let auth = MockAuthService(state: .signedIn(user))
        return (ProfileFormViewModel(authService: auth, user: user), auth)
    }
}
