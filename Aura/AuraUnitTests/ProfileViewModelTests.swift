//
//  ProfileViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func test_lastResultDeleted_returnsToTheLockedScreen_andForgetsTheSavedResult() async {
        // Given
        let storage = makeStorage()
        storage.save(StoredPersonality(historyId: UUID(), result: .mock), for: StorageKeys.personality, userId: UserModel.mock.id)

        // When
        let viewModel = ProfileViewModel(authService: MockAuthService(user: .mock), contentService: MockContentService(), storage: storage)
        await waitUntil { viewModel.user != nil && storage.load(StorageKeys.personality, for: UserModel.mock.id) == nil }

        // Then
        XCTAssertNil(storage.load(StorageKeys.personality, for: UserModel.mock.id))
        XCTAssertFalse(viewModel.hasPersonalityTests)
        XCTAssertEqual(viewModel.profileDisplayHandler, .placeholder)
    }

    // MARK: - Profile form
    func test_form_withOneLetterName_showsAlert_andSendsNothing() async {
        // Given
        let auth = MockAuthService()
        let viewModel = ProfileFormViewModel(authService: auth, user: makeUser())
        viewModel.name = " А "

        // When
        viewModel.saveProfileInfo { }
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Имя должно содержать минимум 2 символа")
        XCTAssertNil(auth.savedProfile)
    }

    func test_form_sendsTheTrimmedName_andAnEmptyTimeWhenItIsUnknown() async {
        // Given
        let auth = MockAuthService()
        let viewModel = ProfileFormViewModel(authService: auth, user: makeUser())
        viewModel.name = "  Анна  "
        var didSave = false

        // When
        viewModel.saveProfileInfo { didSave = true }
        await waitUntil { didSave }

        // Then
        XCTAssertEqual(auth.savedProfile?.name, "Анна")
        XCTAssertEqual(auth.savedProfile?.dateOfBirth, "13.05.2000")
        XCTAssertEqual(auth.savedProfile?.birthTime, "")
    }

    func test_form_serverFailure_showsAlert_andStaysOpen() async {
        // Given
        let auth = MockAuthService()
        auth.errorToThrow = serverError
        let viewModel = ProfileFormViewModel(authService: auth, user: makeUser())
        var didSave = false

        // When
        viewModel.saveProfileInfo { didSave = true }
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertFalse(didSave)
    }
}
