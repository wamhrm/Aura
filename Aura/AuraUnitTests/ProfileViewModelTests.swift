//
//  ProfileViewModelTests.swift
//  AuraUnitTests
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func test_lockedProfile_doesNotLoadTip_andFirstResultUnlocksLoading() async {
        let storage = makeStorage()
        let content = MockContentService()
        let viewModel = ProfileViewModel(authService: MockAuthService(user: makeUser()), contentService: content, storage: storage)
        await waitUntil { viewModel.personalityState == .loaded }
        XCTAssertEqual(content.tipCount, 0)

        let result = HistoryCellModel.personalityPlaceholder
        storage.save(StoredPersonality(historyId: result.id, result: .mock), key: StorageKeys.personality, userId: UserModel.mock.id)
        content.history = [result]
        content.historyDidChange.send()
        await waitUntil { viewModel.tipState == .loaded }

        XCTAssertTrue(viewModel.hasPersonalityTests)
        XCTAssertEqual(content.tipCount, 1)
        XCTAssertNotNil(viewModel.dailyTip)
    }

    func test_failedSignOut_showsError_andKeepsSettingsOpen() {
        let auth = MockAuthService(user: makeUser())
        auth.errorToThrow = serverError
        let viewModel = ProfileViewModel(authService: auth, contentService: MockContentService(), storage: makeStorage())
        viewModel.showSettings = true

        viewModel.signOut()

        XCTAssertTrue(viewModel.showSettings)
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        guard case .signedIn = auth.authState.value else { return XCTFail("Session was ended") }
    }

    func test_lastResultDeleted_returnsToTheLockedScreen_andForgetsTheSavedResult() async {
        // Given
        let storage = makeStorage()
        storage.save(StoredPersonality(historyId: UUID(), result: .mock), key: StorageKeys.personality, userId: UserModel.mock.id)

        // When
        let viewModel = ProfileViewModel(authService: MockAuthService(user: .mock), contentService: MockContentService(), storage: storage)
        await waitUntil { viewModel.user != nil && storage.load(StorageKeys.personality, userId: UserModel.mock.id) == nil }

        // Then
        XCTAssertNil(storage.load(StorageKeys.personality, userId: UserModel.mock.id))
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
