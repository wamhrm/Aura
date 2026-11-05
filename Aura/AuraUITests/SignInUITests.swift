//
//  SignInUITests.swift
//  AuraUITests
//

import XCTest

final class SignInUITests: AuraUITestCase {
    func test_testSessions_keepTheirOwnSessionAndProfile() throws {
        // Given
        try launchSignedIn()
        let originalTestID = try XCTUnwrap(app.launchEnvironment["AURA_UI_TEST_ID"])
        let otherTestID = UUID().uuidString

        // When another test starts
        app.terminate()
        app.launchEnvironment["AURA_UI_TEST_ID"] = otherTestID
        app.launch()

        // Then it has no saved session
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15))

        // When the original test resumes
        app.terminate()
        app.launchEnvironment["AURA_UI_TEST_ID"] = originalTestID
        app.launch()

        // Then its session is still available
        assertOnMainScreen()

        // When another test saves a different profile
        app.terminate()
        app.launchEnvironment["AURA_UI_TEST_ID"] = otherTestID
        let otherUser = try sampleUser(["name": "Мария"])
        server.respond(to: "POST /v1/auth/signIn", body: try authBody(user: otherUser))
        server.respond(to: "GET /v1/auth/me", body: try json(otherUser))
        app.launch()
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15))
        signIn()
        XCTAssertTrue(text("Здравствуйте, Мария").waitForExistence(timeout: 15))

        // Then the original profile restores even when the server is unavailable
        app.terminate()
        app.launchEnvironment["AURA_UI_TEST_ID"] = originalTestID
        server.respond(to: "GET /v1/auth/me", status: 503, body: try failingBody(serverError))
        app.launch()
        XCTAssertTrue(text("Здравствуйте, Анна").waitForExistence(timeout: 15))
    }

    func test_signIn_keepsTheSessionAfterRelaunch() throws {
        // Given
        try launchOnWelcome()

        // When
        signIn()

        // Then
        assertOnMainScreen()

        // When
        app.terminate()
        app.launch()

        // Then
        assertOnMainScreen()
    }

    // The password is shorter than the current minimum: old accounts have such passwords and must reach the server
    func test_signIn_withWrongShortPassword_showsTheServerAlert() throws {
        // Given
        let reason = "Неверная почта или пароль"
        server.respond(to: "POST /v1/auth/signIn", status: 401, body: try failingBody(reason))
        try launchOnWelcome()

        // When
        signIn(password: "short6")

        // Then
        XCTAssertEqual(alertText(), reason)
    }

    func test_signIn_showsAlertsForWrongInput() throws {
        // Given
        try launchOnWelcome()
        welcomeButton.tap()

        // When the fields are empty
        tapButton("Войти")

        // Then
        XCTAssertEqual(alertText(), "Заполните почту и пароль")
        closeAlert()

        // When the email has no @
        fillField(app.textFields["Электронная почта"].firstMatch, with: "no-at-sign")
        fillField(app.secureTextFields["Пароль"].firstMatch, with: password)
        tapButton("Войти")

        // Then
        XCTAssertEqual(alertText(), "Укажите корректный e-mail")
    }

    func test_eyeButton_showsThePassword() throws {
        // Given
        try launchOnWelcome()
        welcomeButton.tap()
        fillField(app.secureTextFields["Пароль"].firstMatch, with: password)

        // When
        app.buttons["eye"].firstMatch.tap()

        // Then
        XCTAssertEqual(app.textFields["Пароль"].firstMatch.value as? String, password)
    }

    func test_createButton_opensRegistration() throws {
        // Given
        try launchOnWelcome()
        welcomeButton.tap()

        // When
        tapButton("Создать")

        // Then
        XCTAssertTrue(text(containing: "Как вас зовут").waitForExistence(timeout: 5), "the registration did not open")
    }

    func test_passwordReset_reachesMainScreen() throws {
        // Given
        try launchOnWelcome()
        welcomeButton.tap()
        fillField(app.textFields["Электронная почта"].firstMatch, with: email)
        tapButton("Забыли пароль?")

        // When
        tapButton("Отправить код")
        fillField(app.textFields["Код из 6 цифр"].firstMatch, with: "123456")
        fillField(app.secureTextFields["Новый пароль"].firstMatch, with: "new-password-1")
        tapButton("Сохранить пароль")

        // Then
        assertOnMainScreen()
    }

    func test_passwordReset_showsAlertsForWrongCode() throws {
        // Given
        let reason = "Неверный код"
        server.respond(to: "POST /v1/auth/password/reset", status: 400, body: try failingBody(reason))
        try launchOnWelcome()
        welcomeButton.tap()
        fillField(app.textFields["Электронная почта"].firstMatch, with: email)
        tapButton("Забыли пароль?")
        tapButton("Отправить код")
        XCTAssertTrue(app.textFields["Код из 6 цифр"].firstMatch.waitForExistence(timeout: 10), "no code field")

        // When the code is too short
        tapButton("Сохранить пароль")

        // Then
        XCTAssertEqual(alertText(), "Введите 6-значный код из письма")
        closeAlert()

        // When the server refuses the code
        fillField(app.textFields["Код из 6 цифр"].firstMatch, with: "123456")
        fillField(app.secureTextFields["Новый пароль"].firstMatch, with: "new-password-1")
        tapButton("Сохранить пароль")

        // Then
        XCTAssertEqual(alertText(), reason)
    }

    func test_whenTheServerEndsTheSession_appReturnsToWelcome() throws {
        // Given
        server.respond(to: "GET /v1/history", status: 401, body: try failingBody("Неверный токен"))
        try launchOnWelcome()

        // When
        signIn()

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 20), "did not return to the welcome screen")
    }
}
