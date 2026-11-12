//
//  ProfileViewModelTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func test_refresh_hidesOutdatedTip_beforeLoadingHistory() async {
        let result = HistoryCellModel.personalityPlaceholder
        let content = MockContentService()
        content.history = [result]
        content.dailyContentDate = "2000-01-01"
        let viewModel = ProfileViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        await waitUntil { viewModel.tipState == .loaded }
        content.dailyContentDate = todayText()
        content.beforeContentResponse = {
            XCTAssertNil(viewModel.dailyTip)
            XCTAssertNil(viewModel.profileDisplayHandler.dailyTip)
        }

        await viewModel.refresh()
        content.beforeContentResponse = nil

        XCTAssertEqual(viewModel.dailyTip?.isFromToday, true)
    }

    func test_profileWithoutABirthDate_doesNotLoadTheTip() async {
        let content = MockContentService()
        let viewModel = ProfileViewModel(authService: MockAuthService(user: makeUser(dateOfBirth: nil)),
                                         contentService: content)
        await waitUntil { viewModel.personalityState == .loaded }

        XCTAssertEqual(content.tipCount, 0)
        XCTAssertNil(viewModel.dailyTip)
    }

    func test_profileWithABirthDate_loadsTheTipWithoutAPersonalityResult() async {
        let content = MockContentService()
        let viewModel = ProfileViewModel(authService: MockAuthService(user: makeUser()),
                                         contentService: content)
        await waitUntil { viewModel.tipState == .loaded }

        XCTAssertFalse(viewModel.hasPersonalityTests)
        XCTAssertGreaterThanOrEqual(content.tipCount, 1)
        XCTAssertNotNil(viewModel.dailyTip)
    }

    func test_failedSignOut_showsError_andKeepsSettingsOpen() async {
        let auth = MockAuthService(user: makeUser())
        auth.errorToThrow = serverError
        let viewModel = ProfileViewModel(authService: auth, contentService: MockContentService())
        viewModel.showSettings = true

        viewModel.signOut()
        await waitUntil { viewModel.showAlert }

        XCTAssertTrue(viewModel.showSettings)
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        guard case .signedIn = auth.authState.value else { return XCTFail("Session was ended") }
    }

    func test_emptyHistory_showsTheLockedProfile() async {
        // When
        let viewModel = ProfileViewModel(authService: MockAuthService(user: .mock), contentService: MockContentService())
        await waitUntil { viewModel.personalityState == .loaded }

        // Then
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
