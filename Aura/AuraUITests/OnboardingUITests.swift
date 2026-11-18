//
//  OnboardingUITests.swift
//  AuraUITests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest

final class OnboardingUITests: AuraUITestCase {
    private func openNameStep() {
        launchOnWelcome()

        for page in ["Гороскоп на неделю", "Инсайт и совет дня", "Тесты о вас и совместимость"] {
            tapButton("Далее")
            XCTAssertTrue(text(page).waitForExistence(timeout: 5), "intro did not move to \(page)")
        }

        tapButton("Начать")
        XCTAssertTrue(app.textFields["Имя"].firstMatch.waitForExistence(timeout: 10), "the name step did not open")
    }

    private func openProfileQuestions() {
        openNameStep()
        fillField(app.textFields["Имя"].firstMatch, text: "Анна")
        tapButton("Далее")
        fillField(app.textFields["Электронная почта"].firstMatch, text: email)
        tapButton("Далее")
        fillField(app.secureTextFields["Пароль"].firstMatch, text: password)
        tapButton("Далее")
        XCTAssertTrue(text("Расскажите о себе").waitForExistence(timeout: 15), "the profile questions did not open")
    }

    private func submitProfileAnswers() {
        chooseAnswers(["Мужской", "Интроверт", "Миротворец", "Рациональный", "Планируете", "Стабильность"])
        tapButton("Далее")
    }

    func test_registration_withUnavailableAI_stillReachesMainScreen() throws {
        // Given
        openProfileQuestions()
        let failure = try failingBody(serverError)
        server.respond(route: "GET /v1/horoscope/current", status: 500, body: failure)
        server.respond(route: "GET /v1/daily/insight", status: 500, body: failure)

        // When
        submitProfileAnswers()
        tapButton("Разрешить")

        // Then
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "AI failure blocked onboarding")
        XCTAssertTrue(text(part: serverError).firstMatch.waitForExistence(timeout: 15), "no content error on the main screen")
    }

    func test_consentFailure_showsError_andAllowsRetry() throws {
        let user = try sampleUser(["hasAIConsent": false])
        server.respond(route: "PATCH /v1/auth/profileInfo", body: try profileBody(user: user))
        server.respond(route: "POST /v1/auth/aiConsent", status: 500, body: try failingBody(serverError))
        openProfileQuestions()
        submitProfileAnswers()
        tapButton("Разрешить")

        XCTAssertTrue(text(part: serverError).waitForExistence(timeout: 15), "consent error was hidden")
        XCTAssertFalse(app.tabBars.firstMatch.exists)

        server.respond(route: "POST /v1/auth/aiConsent", body: try json(sampleUser()))
        confirmAlert("ОК")
        tapButton("Разрешить")
        assertOnMainScreen()
    }

    func test_registration_showsAlertsForWrongInput() {
        // Given
        openNameStep()

        // When the name is empty
        tapButton("Далее")

        // Then
        XCTAssertEqual(alertText(), "Укажите имя")
        closeAlert()

        // When the email has no @
        fillField(app.textFields["Имя"].firstMatch, text: "Анна")
        tapButton("Далее")
        fillField(app.textFields["Электронная почта"].firstMatch, text: "no-at-sign")
        tapButton("Далее")

        // Then
        XCTAssertEqual(alertText(), "Укажите корректный e-mail")
        closeAlert()

        // When the password is too short
        app.textFields["Электронная почта"].firstMatch.typeText("@example.test")
        tapButton("Далее")
        fillField(app.secureTextFields["Пароль"].firstMatch, text: "short")
        tapButton("Далее")

        // Then
        XCTAssertEqual(alertText(), "Пароль должен быть не короче 8 символов")
    }

    func test_birthTimeSwitch_showsTheTimeField() {
        // Given
        openNameStep()
        XCTAssertFalse(text("Время рождения").exists)

        // When
        app.switches["Я знаю время рождения"].switches.firstMatch.tap()

        // Then
        XCTAssertTrue(text("Время рождения").waitForExistence(timeout: 3), "the time field did not appear")
    }

    func test_decliningAIConsent_locksTheScreen_andAllowingUnlocksIt() throws {
        // Given
        let user = try sampleUser(["hasAIConsent": false])
        server.respond(route: "PATCH /v1/auth/profileInfo", body: try profileBody(user: user))
        openProfileQuestions()
        submitProfileAnswers()

        // When
        tapButton("Не сейчас")

        // Then
        XCTAssertTrue(text(part: "Разрешите анализ").waitForExistence(timeout: 20), "no lock on the main screen")
        XCTAssertFalse(text(dailyText).exists)

        // When
        tapButton("Разрешить")
        tapButton("Разрешить")

        // Then
        assertOnMainScreen()
    }

    func test_termsLink_opensInSafari() {
        // Given
        openNameStep()
        fillField(app.textFields["Имя"].firstMatch, text: "Анна")
        tapButton("Далее")
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        let terms = app.links["Условия использования"].firstMatch
        XCTAssertTrue(terms.waitForExistence(timeout: 5), "no link to the terms")

        // When
        terms.tap()

        // Then
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 20), "the link did not open")
        safari.terminate()
    }

    func test_incompleteProfile_afterRelaunch_backArrowOffersToSignOut() throws {
        // Given
        let user = try newUser()
        server.respond(route: "GET /v1/auth/me", body: try json(user))
        server.respond(route: "POST /v1/auth/signIn", body: try authBody(user: user))
        launchOnWelcome()
        signIn()
        XCTAssertTrue(text("Когда вы родились?").waitForExistence(timeout: 15), "the date step did not open")
        app.terminate()
        app.launch()
        XCTAssertTrue(text("Когда вы родились?").waitForExistence(timeout: 15), "the date step did not reopen")
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        let requests = server.requests
        XCTAssertEqual(requests.filter { $0 == "POST /v1/auth/signIn" }.count, 1)
        XCTAssertEqual(requests.filter { $0 == "GET /v1/auth/me" }.count, 1)
        let arrow = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(arrow.waitForExistence(timeout: 15), "the onboarding back button did not appear")

        // When
        arrow.tap()
        confirmAlert("Отмена")

        // Then
        XCTAssertTrue(text("Когда вы родились?").exists)

        // When
        arrow.tap()
        confirmAlert("Выйти")

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15), "did not return to the welcome screen")
    }
}
