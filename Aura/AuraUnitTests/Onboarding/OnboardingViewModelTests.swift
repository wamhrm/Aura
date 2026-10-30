//
//  OnboardingViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    // MARK: - signIn validation
    func test_signIn_whenFieldsEmpty_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = ""
        sut.password = ""

        // When
        sut.signIn()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Заполните почту и пароль")
    }

    func test_signIn_whenEmailInvalid_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = "bad-email"
        sut.password = "123456"

        // When
        sut.signIn()

        // Then
        XCTAssertEqual(sut.alertMessage, "Укажите корректный e-mail")
    }

    func test_signIn_whenPasswordTooShort_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = "a@b.com"
        sut.password = "123"

        // When
        sut.signIn()

        // Then
        XCTAssertEqual(sut.alertMessage, "Пароль должен быть не короче 6 символов")
    }

    // MARK: - sign up validation
    func test_continueFromEmail_whenEmailEmpty_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.email = ""

        // When
        sut.continueFromEmail()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Укажите почту")
    }

    func test_continueFromNameAndBirth_whenNameTooShort_showsAlert() {
        // Given
        let sut = makeSUT()
        sut.name = "A"

        // When
        sut.continueFromNameAndBirth()

        // Then
        XCTAssertEqual(sut.alertMessage, "Имя должно содержать минимум 2 символа")
    }

    // MARK: - Helpers
    private func makeSUT() -> OnboardingViewModel {
        OnboardingViewModel(authService: MockAuthService(),
                            contentService: MockContentService()) {}
    }
}
