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
    func test_initialHistoryAndConsent_haveOneOwnerPerRequest() async {
        let auth = MockAuthService(user: makeUser(hasAIConsent: false))
        let content = MockContentService()
        content.history = [.personalityPlaceholder]
        let profile = ProfileViewModel(authService: auth, contentService: content)
        let history = HistoryViewModel(authService: auth, contentService: content)
        let home = HomeViewModel(authService: auth, contentService: content)
        await waitUntil { profile.hasPersonalityTests && !home.showsLoadingScreen }

        home.allowAIConsent()
        await waitUntil { !home.isLoading && profile.tipState == .loaded }

        XCTAssertEqual(history.historyCells.count, 1)
        XCTAssertEqual(content.fetchHistoryCount, 1)
        XCTAssertEqual(content.detailsCount, 1)
        XCTAssertEqual(content.insightCount, 1)
        XCTAssertEqual(content.tipCount, 1)
    }

    func test_refreshOfTheSameHistory_doesNotRequestDetailsTwice() async {
        let content = MockContentService()
        content.history = [.personalityPlaceholder]
        let viewModel = ProfileViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        await waitUntil { viewModel.user != nil }

        await viewModel.refresh()
        await waitUntil { viewModel.hasPersonalityTests }
        await viewModel.refresh()

        XCTAssertEqual(content.detailsCount, 1)
    }

    func test_lateDetails_doNotRestoreADeletedPersonality() async {
        let content = MockContentService()
        content.history = [.personalityPlaceholder]
        let viewModel = ProfileViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        await waitUntil { viewModel.user != nil }
        content.beforeDetailsResponse = { content.historyCells.send([]) }

        await viewModel.refresh()
        await waitUntil { content.detailsCount == 1 && viewModel.personalityState == .loaded }

        XCTAssertFalse(viewModel.hasPersonalityTests)
        XCTAssertEqual(viewModel.profileDisplay, .placeholder)
    }

    func test_historyFailure_isVisibleOnProfile_andRetryLoadsTheResult() async {
        let auth = MockAuthService(user: makeUser())
        let content = MockContentService()
        content.errorToThrow = serverError
        let viewModel = ProfileViewModel(authService: auth, contentService: content)
        let history = HistoryViewModel(authService: auth, contentService: content)
        await waitUntil { viewModel.personalityState == .failed("Ошибка сервера") }
        XCTAssertEqual(history.loadState, .failed("Ошибка сервера"))
        content.errorToThrow = nil
        content.history = [.personalityPlaceholder]

        viewModel.retryPersonality()
        await waitUntil { viewModel.hasPersonalityTests }

        XCTAssertEqual(viewModel.personalityState, .loaded)
        XCTAssertEqual(history.historyCells.count, 1)
    }

    func test_form_rejectsAnOverlongName_andCapitalizesTheTrimmedName() throws {
        let form = ProfileFormViewModel(user: makeUser())
        form.name = String(repeating: "A", count: InputLimits.maxNameLength + 1)
        XCTAssertThrowsError(try form.profileInfoRequest())
        form.name = "  o’connor  "

        XCTAssertEqual(try form.profileInfoRequest().name, "O’connor")
    }

    func test_refresh_rejectsOutdatedTip_andRecovers() async {
        let result = HistoryCellModel.personalityPlaceholder
        let content = MockContentService()
        content.history = [result]
        content.historyCells.send([result])
        content.dailyContentDate = "2000-01-01"
        let viewModel = ProfileViewModel(authService: MockAuthService(user: makeUser()), contentService: content)
        await waitUntil { viewModel.tipState == .failed(NetworkError.invalidResponse.userMessage) && viewModel.hasPersonalityTests }
        XCTAssertNil(viewModel.dailyTip)
        XCTAssertNil(viewModel.profileDisplay.dailyTip)
        content.dailyContentDate = todayText()
        content.beforeContentResponse = {
            XCTAssertNil(viewModel.dailyTip)
            XCTAssertNil(viewModel.profileDisplay.dailyTip)
        }

        await viewModel.refresh()
        content.beforeContentResponse = nil

        XCTAssertEqual(viewModel.tipState, .loaded)
        XCTAssertEqual(viewModel.dailyTip?.isFromToday, true)
    }

    func test_profileWithoutConsentOrABirthDate_doesNotLoadTheTip() async {
        for user in [makeUser(dateOfBirth: nil), makeUser(hasAIConsent: false)] {
            let content = MockContentService()
            let viewModel = ProfileViewModel(authService: MockAuthService(user: user),
                                             contentService: content)
            await waitUntil { viewModel.personalityState == .loaded }

            XCTAssertEqual(content.tipCount, 0)
            XCTAssertNil(viewModel.dailyTip)
        }
    }

    func test_profileWithConsentAndABirthDate_loadsTheTipWithoutAPersonalityResult() async {
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
        guard case .signedIn = auth.authState else { return XCTFail("Session was ended") }
    }

    func test_emptyHistory_showsTheLockedProfile() async {
        // When
        let viewModel = ProfileViewModel(authService: MockAuthService(user: .mock), contentService: MockContentService())
        await waitUntil { viewModel.personalityState == .loaded }

        // Then
        XCTAssertFalse(viewModel.hasPersonalityTests)
        XCTAssertEqual(viewModel.profileDisplay, .placeholder)
    }

    // MARK: - Profile form
    func test_form_withOneLetterName_showsAlert_andSendsNothing() async throws {
        let auth = MockAuthService(user: makeUser())
        let viewModel = ProfileViewModel(authService: auth, contentService: MockContentService())
        await waitUntil { viewModel.user != nil }
        viewModel.showAddProfileInfo()
        let form = try XCTUnwrap(viewModel.profileForm)
        form.name = " А "

        viewModel.saveProfileInfo()

        XCTAssertEqual(form.alertMessage, "Имя должно содержать минимум 2 символа")
        XCTAssertTrue(form.showAlert)
        XCTAssertFalse(viewModel.isSavingProfile)
        XCTAssertNil(auth.savedProfile)
    }

    func test_form_savesUnderLoading_andIgnoresRepeatedTap() async throws {
        let auth = MockAuthService(user: makeUser())
        let viewModel = ProfileViewModel(authService: auth, contentService: MockContentService())
        await waitUntil { viewModel.user != nil }
        viewModel.showAddProfileInfo()
        let form = try XCTUnwrap(viewModel.profileForm)
        form.name = "  Анна  "
        var loadingWhenNavigating: [Bool] = []
        let subscription = viewModel.$profileRoutes.dropFirst().sink { _ in
            loadingWhenNavigating.append(viewModel.isSavingProfile)
        }
        defer { subscription.cancel() }

        viewModel.saveProfileInfo()
        viewModel.saveProfileInfo()
        await waitUntil { !viewModel.isSavingProfile }

        XCTAssertEqual(auth.savedProfile?.name, "Анна")
        XCTAssertEqual(auth.savedProfile?.dateOfBirth, "13.05.2000")
        XCTAssertEqual(auth.savedProfile?.birthTime, "")
        XCTAssertEqual(loadingWhenNavigating, [true])
        XCTAssertTrue(viewModel.profileRoutes.isEmpty)
        XCTAssertNil(viewModel.profileForm)
    }

    func test_form_serverFailure_showsAlert_andStaysOpen() async throws {
        let auth = MockAuthService(user: makeUser())
        auth.errorToThrow = serverError
        let viewModel = ProfileViewModel(authService: auth, contentService: MockContentService())
        await waitUntil { viewModel.user != nil }
        viewModel.showAddProfileInfo()
        let form = try XCTUnwrap(viewModel.profileForm)
        form.name = "Анна-Мария"

        viewModel.saveProfileInfo()
        await waitUntil { form.showAlert }

        XCTAssertEqual(form.alertMessage, "Ошибка сервера")
        XCTAssertFalse(viewModel.isSavingProfile)
        XCTAssertTrue(viewModel.profileForm === form)
        XCTAssertEqual(viewModel.profileRoutes, [.addProfileInfo])
        XCTAssertEqual(form.name, "Анна-Мария")
    }
}
