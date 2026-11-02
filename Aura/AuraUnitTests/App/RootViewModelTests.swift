//
//  RootViewModelTests.swift
//  AuraUnitTests
//

import Combine
import SwiftUI
import XCTest
@testable import Aura

@MainActor
final class RootViewModelTests: XCTestCase {
    func test_init_chooseTheScreenByProfile() {
        // Given / When
        let complete = makeSUT(state: .signedIn(.mock)).sut
        let incomplete = makeSUT(state: .signedIn(makeIncompleteUser())).sut
        let signedOut = makeSUT(state: .signedOut).sut

        // Then
        XCTAssertEqual(complete.screen, .main)
        XCTAssertEqual(incomplete.screen, .onboarding)
        XCTAssertEqual(signedOut.screen, .onboarding)
    }

    func test_signOutOnMainScreen_returnsToOnboarding() async {
        // Given
        let (sut, auth, _) = makeSUT(state: .signedIn(.mock))

        // When
        auth.authState.send(.signedOut)
        await waitUntil { sut.screen == .onboarding }

        // Then
        XCTAssertEqual(sut.screen, .onboarding)
    }

    // MARK: - Return to the app
    func test_handleScenePhase_whenIntervalPassed_refreshesUserAndContent() {
        // Given
        let (sut, auth, content) = makeSUT(state: .signedIn(.mock), refreshInterval: 0)
        var refreshes = 0
        let cancellable = content.refreshRequested.sink { refreshes += 1 }

        // When
        sut.handleScenePhase(.active)

        // Then
        XCTAssertEqual(auth.refreshUserCallCount, 1)
        XCTAssertEqual(refreshes, 1)
        cancellable.cancel()
    }

    func test_handleScenePhase_whenTooSoon_doesNotRefresh() {
        // Given
        let (sut, auth, content) = makeSUT(state: .signedIn(.mock))
        var refreshes = 0
        let cancellable = content.refreshRequested.sink { refreshes += 1 }

        // When
        sut.handleScenePhase(.active)

        // Then
        XCTAssertEqual(auth.refreshUserCallCount, 0)
        XCTAssertEqual(refreshes, 0)
        cancellable.cancel()
    }

    func test_handleScenePhase_whenNotActive_doesNothing() {
        // Given
        let (sut, auth, _) = makeSUT(state: .signedOut, refreshInterval: 0)

        // When
        sut.handleScenePhase(.background)
        sut.handleScenePhase(.inactive)

        // Then
        XCTAssertEqual(auth.refreshUserCallCount, 0)
        XCTAssertEqual(auth.restoreSessionCallCount, 0)
    }

    // MARK: - Keychain after a restart
    func test_handleScenePhase_whenSessionBecomesReadable_opensMainScreen() {
        // Given
        let (sut, auth, _) = makeSUT(state: .signedOut)
        auth.stateAfterRestore = .signedIn(.mock)

        // When
        sut.handleScenePhase(.active)

        // Then
        XCTAssertEqual(auth.restoreSessionCallCount, 1)
        XCTAssertEqual(sut.screen, .main)
    }

    func test_handleScenePhase_whenStillSignedOut_staysOnOnboarding() {
        // Given
        let (sut, auth, _) = makeSUT(state: .signedOut)

        // When
        sut.handleScenePhase(.active)

        // Then
        XCTAssertEqual(auth.restoreSessionCallCount, 1)
        XCTAssertEqual(sut.screen, .onboarding)
    }

    func test_handleScenePhase_duringOnboardingOfSignedInUser_doesNotSkipIt() {
        // Given
        let (sut, auth, _) = makeSUT(state: .signedIn(makeIncompleteUser()))
        auth.authState.send(.signedIn(.mock))

        // When
        sut.handleScenePhase(.active)

        // Then
        XCTAssertEqual(auth.restoreSessionCallCount, 0)
        XCTAssertEqual(sut.screen, .onboarding)
    }

    // MARK: - Helpers
    private func makeSUT(state: AuthState, refreshInterval: TimeInterval = 300)
        -> (sut: RootViewModel, auth: MockAuthService, content: MockContentService) {
        let auth = MockAuthService(state: state)
        let content = MockContentService()
        let sut = RootViewModel(authService: auth, contentService: content, refreshInterval: refreshInterval)
        return (sut, auth, content)
    }
}
