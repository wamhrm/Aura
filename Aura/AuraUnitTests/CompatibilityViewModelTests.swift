//
//  CompatibilityViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class CompatibilityViewModelTests: XCTestCase {
    func test_partnerName_ofSpacesAndOneLetter_showsAlert_andSendsNothing() async {
        // Given
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(), contentService: content)
        viewModel.partnerInfo.name = "  А  "

        // When
        viewModel.makeCompatibilityTest()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Имя партнёра должно содержать минимум 2 символа")
        XCTAssertTrue(content.compatibilityRequests.isEmpty)
    }

    func test_chosenGender_goesToTheServerAsItsKey() async {
        // Given
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(), contentService: content)
        viewModel.partnerInfo.name = "Анна"

        // When
        viewModel.selectGender(.female)
        viewModel.makeCompatibilityTest()
        await waitUntil { !content.compatibilityRequests.isEmpty }

        // Then
        XCTAssertEqual(content.compatibilityRequests.first?.partnerGender, "woman")
    }

    func test_serverFailure_keepsTheFormFilled() async {
        // Given
        let content = MockContentService()
        content.errorToThrow = serverError
        let viewModel = CompatibilityViewModel(authService: MockAuthService(), contentService: content)
        viewModel.partnerInfo.name = "Анна"

        // When
        viewModel.makeCompatibilityTest()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertEqual(viewModel.partnerInfo.name, "Анна")
        XCTAssertTrue(viewModel.compatibilityRoutes.isEmpty)
    }

    func test_unconfirmedEmail_opensTheSheet_insteadOfTheTest() async {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false, isEmailConfirmed: false))
        let viewModel = CompatibilityViewModel(authService: auth, contentService: MockContentService())
        await waitUntil { viewModel.needsAIConsent }
        viewModel.partnerInfo.name = "Анна"

        // When
        viewModel.makeCompatibilityTest()

        // Then
        XCTAssertNotNil(viewModel.emailConfirmation)
        XCTAssertFalse(viewModel.isLoading)
    }
}
