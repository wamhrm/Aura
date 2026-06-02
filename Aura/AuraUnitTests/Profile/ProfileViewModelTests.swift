//
//  ProfileViewModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class ProfileViewModelTests: XCTestCase {
    // MARK: - signIn validation
    func test_signIn_whenFieldsEmpty_showsAlert() {
        // Given
        let (sut, _) = makeSUT()
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
        let (sut, _) = makeSUT()
        sut.email = "bad-email"
        sut.password = "123456"

        // When
        sut.signIn()

        // Then
        XCTAssertEqual(sut.alertMessage, "Укажите корректный e-mail")
    }

    func test_signIn_whenPasswordTooShort_showsAlert() {
        // Given
        let (sut, _) = makeSUT()
        sut.email = "a@b.com"
        sut.password = "123"

        // When
        sut.signIn()

        // Then
        XCTAssertEqual(sut.alertMessage, "Пароль должен быть не короче 6 символов")
    }

    // MARK: - createAccount validation
    func test_createAccount_whenFieldsEmpty_showsAlert() {
        // Given
        let (sut, _) = makeSUT()

        // When
        sut.createAccount()

        // Then
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Заполните имя, почту и пароль")
    }

    func test_createAccount_whenNameTooShort_showsAlert() {
        // Given
        let (sut, _) = makeSUT()
        sut.name = "A"
        sut.email = "a@b.com"
        sut.password = "123456"

        // When
        sut.createAccount()

        // Then
        XCTAssertEqual(sut.alertMessage, "Имя должно содержать минимум 2 символа")
    }

    // MARK: - Auth mode switching
    func test_dismissSignInCreateViews_resetsBothFlags() {
        // Given
        let (sut, _) = makeSUT()
        sut.showSignIn = true
        sut.showCreateAccount = true

        // When
        sut.dismissSignInCreateViews()

        // Then
        XCTAssertFalse(sut.showSignIn)
        XCTAssertFalse(sut.showCreateAccount)
    }

    func test_toggleSignInCreateView_togglesBothFlags() {
        // Given
        let (sut, _) = makeSUT()
        sut.showSignIn = true
        sut.showCreateAccount = false

        // When
        sut.toggleSignInCreateView()

        // Then
        XCTAssertFalse(sut.showSignIn)
        XCTAssertTrue(sut.showCreateAccount)
    }

    func test_clearTextFields_emptiesAllFields() {
        // Given
        let (sut, _) = makeSUT()
        sut.name = "Имя"
        sut.email = "a@b.com"
        sut.password = "123456"

        // When
        sut.clearTextFields()

        // Then
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
    }

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
        let sut = ProfileViewModel(authService: auth, contentService: MockContentService())
        return (sut, auth)
    }
}
