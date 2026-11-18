//
//  SignInUITests.swift
//  AuraUITests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest

final class SignInUITests: AuraUITestCase {
    func test_relaunch_loadsCurrentUserWithTheSavedToken() throws {
        try launchSignedIn()
        assertOnMainScreen()
        app.terminate()
        server.respond(route: "GET /v1/auth/me", body: try json(sampleUser(["name": "Мария"])))

        app.launch()

        XCTAssertTrue(text("Здравствуйте, Мария").waitForExistence(timeout: 15))
        assertOnMainScreen()
        XCTAssertEqual(server.requests.filter { $0 == "POST /v1/auth/signIn" }.count, 1)
        XCTAssertEqual(server.requests.filter { $0 == "GET /v1/auth/me" }.count, 1)
    }

    func test_relaunch_withIncompleteProfile_continuesOnboarding() throws {
        let user = try newUser()
        server.respond(route: "POST /v1/auth/signIn", body: try authBody(user: user))
        server.respond(route: "GET /v1/auth/me", body: try json(user))
        launchOnWelcome()
        signIn()
        XCTAssertTrue(text("Когда вы родились?").waitForExistence(timeout: 15))
        app.terminate()

        app.launch()

        XCTAssertTrue(text("Когда вы родились?").waitForExistence(timeout: 15))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        XCTAssertEqual(server.requests.filter { $0 == "POST /v1/auth/signIn" }.count, 1)
        XCTAssertEqual(server.requests.filter { $0 == "GET /v1/auth/me" }.count, 1)
    }

    func test_relaunch_whenUserRequestFails_keepsTokenAndAllowsRetry() throws {
        try launchSignedIn()
        assertOnMainScreen()
        app.terminate()
        server.respond(route: "GET /v1/auth/me", status: 503, body: try failingBody(serverError))

        app.launch()

        XCTAssertTrue(text(serverError).waitForExistence(timeout: 15))
        XCTAssertFalse(welcomeButton.exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        XCTAssertTrue(app.buttons["Повторить"].firstMatch.isHittable)
        server.respond(route: "GET /v1/auth/me", body: try json(sampleUser()))
        tapButton("Повторить")

        assertOnMainScreen()
        XCTAssertEqual(server.requests.filter { $0 == "POST /v1/auth/signIn" }.count, 1)
        XCTAssertEqual(server.requests.filter { $0 == "GET /v1/auth/me" }.count, 2)
    }

    func test_relaunch_withRejectedToken_returnsToSignIn() throws {
        try launchSignedIn()
        assertOnMainScreen()
        app.terminate()
        server.respond(route: "GET /v1/auth/me", status: 401, body: try failingBody("Неверный токен"))

        app.launch()

        XCTAssertEqual(alertText(), "Сессия истекла. Войдите снова")
        closeAlert()
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 10))
        XCTAssertEqual(server.requests.filter { $0 == "GET /v1/auth/me" }.count, 1)
    }

    func test_signIn_withWrongShortPassword_showsTheServerAlert() throws {
        // Given
        let reason = "Неверная почта или пароль"
        server.respond(route: "POST /v1/auth/signIn", status: 401, body: try failingBody(reason))
        launchOnWelcome()

        // When
        signIn(password: "short6")

        // Then
        XCTAssertEqual(alertText(), reason)
    }

    func test_signIn_showsAlertsForWrongInput() {
        // Given
        launchOnWelcome()
        welcomeButton.tap()

        // When the fields are empty
        tapButton("Войти")

        // Then
        XCTAssertEqual(alertText(), "Заполните почту и пароль")
        closeAlert()

        // When the email has no @
        fillField(app.textFields["Электронная почта"].firstMatch, text: "no-at-sign")
        fillField(app.secureTextFields["Пароль"].firstMatch, text: password)
        tapButton("Войти")

        // Then
        XCTAssertEqual(alertText(), "Укажите корректный e-mail")
    }

    func test_eyeButton_showsThePassword() {
        // Given
        launchOnWelcome()
        welcomeButton.tap()
        fillField(app.secureTextFields["Пароль"].firstMatch, text: password)

        // When
        app.buttons["eye"].firstMatch.tap()

        // Then
        XCTAssertEqual(app.textFields["Пароль"].firstMatch.value as? String, password)
    }

    func test_createButton_opensRegistration() {
        // Given
        launchOnWelcome()
        welcomeButton.tap()

        // When
        tapButton("Создать")

        // Then
        XCTAssertTrue(text(part: "Как вас зовут").waitForExistence(timeout: 5), "the registration did not open")
    }

    func test_passwordReset_atDailySendLimit_acceptsTheExistingCode() throws {
        // Given
        let sendCode = "POST /v1/auth/password/forgot"
        let dailyLimit = "Слишком много запросов. Попробуйте завтра"
        server.respond(route: sendCode, status: 429,
                       body: try failingBody(dailyLimit),
                       headers: ["X-Aura-Error-Code": "email_code_daily_limit"])
        launchOnWelcome()
        welcomeButton.tap()
        fillField(app.textFields["Электронная почта"].firstMatch, text: email)
        tapButton("Забыли пароль?")

        // When
        tapButton("Отправить код")
        XCTAssertEqual(alertText(), dailyLimit)
        closeAlert()
        fillField(app.textFields["Код из 6 цифр"].firstMatch, text: "123456")
        tapButton("eye")
        let newPassword = app.textFields["Новый пароль"].firstMatch
        fillField(newPassword, text: "new-password-1")
        XCTAssertEqual(newPassword.value as? String, "new-password-1")
        tapButton("Сохранить пароль")

        // Then
        assertOnMainScreen()
        XCTAssertEqual(server.requests.filter { $0 == sendCode }.count, 1)
    }

    func test_passwordReset_showsAlertsForWrongCode() throws {
        // Given
        let reason = "Неверный код"
        server.respond(route: "POST /v1/auth/password/reset", status: 400, body: try failingBody(reason))
        launchOnWelcome()
        welcomeButton.tap()
        fillField(app.textFields["Электронная почта"].firstMatch, text: email)
        tapButton("Забыли пароль?")
        tapButton("Отправить код")
        XCTAssertTrue(app.textFields["Код из 6 цифр"].firstMatch.waitForExistence(timeout: 10), "no code field")

        // When the code is too short
        tapButton("Сохранить пароль")

        // Then
        XCTAssertEqual(alertText(), "Введите 6-значный код из письма")
        closeAlert()

        // When the server refuses the code
        fillField(app.textFields["Код из 6 цифр"].firstMatch, text: "123456")
        fillField(app.secureTextFields["Новый пароль"].firstMatch, text: "new-password-1")
        tapButton("Сохранить пароль")

        // Then
        XCTAssertEqual(alertText(), reason)
    }

    func test_whenTheServerEndsTheSession_appReturnsToWelcome() throws {
        // Given
        server.respond(route: "GET /v1/history", status: 401, body: try failingBody("Неверный токен"))
        launchOnWelcome()

        // When
        signIn()

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 20), "did not return to the welcome screen")
    }
}
