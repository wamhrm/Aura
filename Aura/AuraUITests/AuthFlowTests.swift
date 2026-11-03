//
//  AuthFlowTests.swift
//  AuraUITests
//

import XCTest

final class AuthFlowTests: FlowTestCase {
    func test_registration_reachesMainScreen() throws {
        // Given
        try launchOnWelcome()

        // When
        for title in ["Далее", "Далее", "Далее", "Начать"] {
            tapButton(title)
            sleep(1)
        }
        fillField(app.textFields["Имя"].firstMatch, with: "Анна")
        tapButton("Далее")
        fillField(app.textFields["Электронная почта"].firstMatch, with: email)
        tapButton("Далее")
        fillField(app.secureTextFields["Пароль"].firstMatch, with: password)
        tapButton("Создать аккаунт")
        XCTAssertTrue(text("Расскажите о себе").waitForExistence(timeout: 15), "the profile questions did not open")
        for answer in ["Мужской", "Интроверт", "Миротворец", "Рациональный", "Планируете", "Стабильность"] {
            let chip = text(answer)
            for _ in 0..<5 where !chip.isHittable {
                app.swipeUp()
            }
            chip.tap()
        }
        tapButton("Далее")
        tapButton("Разрешить")

        // Then
        assertOnMainScreen()
        XCTAssertTrue(server.requests.contains("POST /v1/auth/createAccount"))
        XCTAssertTrue(server.requests.contains("PATCH /v1/auth/profileInfo"))
    }

    func test_signIn_keepsSessionAfterRelaunch_andSignOutReturnsToWelcome() throws {
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

        // When
        signOut()

        // Then
        XCTAssertTrue(server.requests.contains("POST /v1/auth/logout"))
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

    func test_passwordReset_reachesMainScreen() throws {
        // Given
        try launchOnWelcome()
        welcomeButton.tap()
        fillField(app.textFields["Электронная почта"].firstMatch, with: email)

        // When
        tapButton("Забыли пароль?")
        tapButton("Отправить код")
        fillField(app.textFields["Код из 6 цифр"].firstMatch, with: "123456")
        fillField(app.secureTextFields["Новый пароль"].firstMatch, with: "new-password-1")
        tapButton("Сохранить пароль")

        // Then
        assertOnMainScreen()
        XCTAssertTrue(server.requests.contains("POST /v1/auth/password/forgot"))
        XCTAssertTrue(server.requests.contains("POST /v1/auth/password/reset"))
    }

    func test_deleteAccount_returnsToWelcome() throws {
        // Given
        try launchSignedIn()
        openProfile()

        // When
        app.buttons["gearshape"].firstMatch.tap()
        tapButton("Удалить аккаунт")
        confirmAlert("Удалить")

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15), "did not return to the welcome screen")
        XCTAssertTrue(server.requests.contains("DELETE /v1/auth/account"))
    }

    func test_incompleteProfile_afterRelaunch_canSignOut() throws {
        // Given
        server.respond(to: "POST /v1/auth/signIn", body: try newUserAuth())
        try launchOnWelcome()
        signIn()
        XCTAssertTrue(text("Когда вы родились?").waitForExistence(timeout: 15), "the date step did not open")
        server.respond(to: "GET /v1/auth/me", body: try newUser())

        // When
        app.terminate()
        app.launch()
        XCTAssertTrue(text("Когда вы родились?").waitForExistence(timeout: 15), "the date step did not reopen")
        let arrow = app.buttons["chevron.left"].firstMatch
        XCTAssertTrue(arrow.waitForExistence(timeout: 10), "no back arrow")
        arrow.tap()
        confirmAlert("Выйти")

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15), "did not return to the welcome screen")
    }

    func test_termsLink_opensInSafari() throws {
        // Given
        try launchOnWelcome()
        welcomeButton.tap()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

        // When
        let terms = app.links["Условия использования"].firstMatch
        XCTAssertTrue(terms.waitForExistence(timeout: 5), "no link to the terms")
        terms.tap()

        // Then
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 20), "the link did not open")
        safari.terminate()
    }
}
