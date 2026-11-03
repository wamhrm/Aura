//
//  CompatibilityViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class CompatibilityViewModelTests: XCTestCase {
    private func fillPartnerForm(_ viewModel: CompatibilityViewModel) {
        viewModel.partnerInfo.name = "Анна"
        viewModel.partnerInfo.answers.socialType = "introvert"
        viewModel.partnerInfo.answers.conflictStyle = "direct"
        viewModel.partnerInfo.answers.emotionalCore = "logic"
        viewModel.partnerInfo.answers.decisionStyle = "planner"
        viewModel.partnerInfo.answers.coreFocus = "growth"
    }

    func test_partnerName_ofSpacesAndOneLetter_showsAlert_andSendsNothing() async {
        // Given
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(), contentService: content)
        fillPartnerForm(viewModel)
        viewModel.partnerInfo.name = "  А  "

        // When
        viewModel.makeCompatibilityTest()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Имя партнёра должно содержать минимум 2 символа")
        XCTAssertTrue(content.compatibilityRequests.isEmpty)
    }

    func test_missingPartnerAnswer_showsAlert_andSendsNothing() async {
        // Given
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(), contentService: content)
        fillPartnerForm(viewModel)
        viewModel.partnerInfo.answers.coreFocus = nil

        // When
        viewModel.makeCompatibilityTest()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Ответьте на все вопросы о партнёре")
        XCTAssertTrue(content.compatibilityRequests.isEmpty)
    }

    func test_chosenGender_goesToTheServerAsItsKey() async {
        // Given
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(), contentService: content)
        fillPartnerForm(viewModel)

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
        fillPartnerForm(viewModel)

        // When
        viewModel.makeCompatibilityTest()
        await waitUntil { viewModel.showAlert }

        // Then
        XCTAssertEqual(viewModel.alertMessage, "Ошибка сервера")
        XCTAssertEqual(viewModel.partnerInfo.name, "Анна")
        XCTAssertTrue(viewModel.partnerInfo.hasAllAnswers)
        XCTAssertTrue(viewModel.compatibilityRoutes.isEmpty)
    }

    func test_unconfirmedEmail_opensTheSheet_insteadOfTheTest() async {
        // Given
        let auth = MockAuthService(user: makeUser(hasAIConsent: false, isEmailConfirmed: false))
        let viewModel = CompatibilityViewModel(authService: auth, contentService: MockContentService())
        await waitUntil { viewModel.needsAIConsent }
        fillPartnerForm(viewModel)

        // When
        viewModel.makeCompatibilityTest()

        // Then
        XCTAssertNotNil(viewModel.emailConfirmation)
        XCTAssertFalse(viewModel.isLoading)
    }
}
