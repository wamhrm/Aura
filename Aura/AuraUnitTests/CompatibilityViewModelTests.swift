//
//  CompatibilityViewModelTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import Combine
import XCTest
@testable import Aura

@MainActor
final class CompatibilityViewModelTests: XCTestCase {
    func test_partnerNameLongerThanTheLimit_sendsNothing() async {
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(), contentService: content)
        viewModel.partnerInfo.name = String(repeating: "A", count: InputLimits.maxNameLength + 1)

        viewModel.makeCompatibilityTest()
        await waitUntil { viewModel.showAlert }

        XCTAssertTrue(content.compatibilityRequests.isEmpty)
    }

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

    func test_retry_reusesTheRequestID_untilTheUserOrPartnerChanges() async throws {
        // Given
        let content = MockContentService()
        content.errorToThrow = serverError
        let auth = MockAuthService(user: makeUser())
        let viewModel = CompatibilityViewModel(authService: auth, contentService: content)
        viewModel.partnerInfo.name = "Анна"

        // When the same form is retried
        viewModel.makeCompatibilityTest()
        await waitUntil { content.compatibilityRequestIDs.count == 1 }
        viewModel.makeCompatibilityTest()
        await waitUntil { content.compatibilityRequestIDs.count == 2 }

        // Then
        let firstID = try XCTUnwrap(content.compatibilityRequestIDs.first)
        XCTAssertEqual(content.compatibilityRequestIDs, [firstID, firstID])

        // When the signed-in user changes
        auth.authState.send(.signedIn(makeUser(name: "Мария")))
        viewModel.makeCompatibilityTest()
        await waitUntil { content.compatibilityRequestIDs.count == 3 }

        // Then
        XCTAssertNotEqual(content.compatibilityRequestIDs.last, firstID)

        // When the partner changes
        let changedUserID = try XCTUnwrap(content.compatibilityRequestIDs.last)
        viewModel.partnerInfo.name = "Иван"
        viewModel.makeCompatibilityTest()
        await waitUntil { content.compatibilityRequestIDs.count == 4 }

        // Then
        XCTAssertNotEqual(content.compatibilityRequestIDs.last, changedUserID)
    }
    func test_resultRoute_isAddedUnderLoading_andRepeatedTapSendsOneRequest() async {
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(user: makeUser()),
                                               contentService: content)
        viewModel.partnerInfo.name = "Анна"
        var loadingWhenNavigating: [Bool] = []
        let subscription = viewModel.$compatibilityRoutes.dropFirst().sink { _ in
            loadingWhenNavigating.append(viewModel.isLoading)
        }
        defer { subscription.cancel() }

        viewModel.makeCompatibilityTest()
        viewModel.makeCompatibilityTest()
        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(content.compatibilityRequests.count, 1)
        XCTAssertEqual(viewModel.compatibilityRoutes, [.compatibilityResults])
        XCTAssertEqual(loadingWhenNavigating, [true])
    }

}
