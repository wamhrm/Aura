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
final class CompatibilityViewModelTests: AuraUnitTestCase {
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
        auth.publishUser(makeUser(name: "Мария"))
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

    func test_newTest_afterSuccess_usesANewRequestIDForTheSamePartner() async {
        let content = MockContentService()
        let viewModel = CompatibilityViewModel(authService: MockAuthService(user: makeUser()),
                                               contentService: content)
        viewModel.partnerInfo.name = "Анна"
        viewModel.makeCompatibilityTest()
        await waitUntil { !viewModel.isLoading }

        viewModel.compatibilityRoutes = []
        viewModel.partnerInfo.name = "Анна"
        viewModel.makeCompatibilityTest()
        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(content.compatibilityRequests.count, 2)
        XCTAssertEqual(content.compatibilityRequests.first, content.compatibilityRequests.last)
        XCTAssertNotEqual(content.compatibilityRequestIDs.first, content.compatibilityRequestIDs.last)
    }

    func test_sexualTest_appearsOnlyWhenBothAre18() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let minorBirthDate = try XCTUnwrap(calendar.date(byAdding: .year, value: -17, to: Date()))
        let adult = makeUser()
        let minor = makeUser(id: adult.id, dateOfBirth: BirthDateFormatter.dateString(date: minorBirthDate))
        let auth = MockAuthService(user: adult)
        let viewModel = CompatibilityViewModel(authService: auth, contentService: MockContentService())
        await waitUntil { viewModel.availableTests.contains(.sexualCompatibility) }
        XCTAssertFalse(viewModel.selectedTests.contains(.sexualCompatibility))

        viewModel.toggleTestSelection(.sexualCompatibility)
        XCTAssertTrue(viewModel.selectedTests.contains(.sexualCompatibility))
        auth.publishUser(minor)
        await waitUntil { !viewModel.availableTests.contains(.sexualCompatibility) }
        XCTAssertFalse(viewModel.selectedTests.contains(.sexualCompatibility))

        auth.publishUser(adult)
        await waitUntil { viewModel.availableTests.contains(.sexualCompatibility) }
        viewModel.toggleTestSelection(.sexualCompatibility)
        XCTAssertTrue(viewModel.selectedTests.contains(.sexualCompatibility))

        viewModel.partnerInfo.birthDate = minorBirthDate
        XCTAssertFalse(viewModel.availableTests.contains(.sexualCompatibility))
        XCTAssertFalse(viewModel.selectedTests.contains(.sexualCompatibility))
    }
}
