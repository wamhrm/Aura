//
//  ProfileViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class ProfileViewModelTests: XCTestCase {
    // MARK: - signOut
    func test_signOut_callsAuthServiceAndHidesSettings() {
        // Given
        let (sut, auth) = makeSUT()
        sut.showSettings = true

        // When
        sut.signOut()

        // Then
        XCTAssertEqual(auth.signOutCallCount, 1)
        XCTAssertFalse(sut.showSettings)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: ProfileViewModel, auth: MockAuthService) {
        let auth = MockAuthService()
        let sut = ProfileViewModel(authService: auth, contentService: MockContentService(), storage: MockLocalStorage())
        return (sut, auth)
    }
}
