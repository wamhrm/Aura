//
//  OnboardingUITests.swift
//  AuraUITests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest

final class OnboardingUITests: AuraUITestCase {
    private func openNameStep() throws {
        try launchOnWelcome()

        for page in ["Гороскоп на неделю", "Инсайт и совет дня", "Тесты о вас и совместимость"] {
            tapButton("Далее")
            XCTAssertTrue(text(page).waitForExistence(timeout: 5), "intro did not move to \(page)")
        }

        tapButton("Начать")
        XCTAssertTrue(app.textFields["Имя"].firstMatch.waitForExistence(timeout: 10), "the name step did not open")
    }

    private func openProfileQuestions() throws {
        try openNameStep()
        fillField(app.textFields["Имя"].firstMatch, text: "Анна")
        tapButton("Далее")
        fillField(app.textFields["Электронная почта"].firstMatch, text: email)
        tapButton("Далее")
        fillField(app.secureTextFields["Пароль"].firstMatch, text: password)
        tapButton("Далее")
        XCTAssertTrue(text("Расскажите о себе").waitForExistence(timeout: 15), "the profile questions did not open")
    }

    func test_registration_withUnavailableAI_stillReachesMainScreen() throws {
        // Given
        try openProfileQuestions()
        let failure = try failingBody(serverError)
        server.respond(route: "GET /v1/horoscope/current", status: 500, body: failure)
        server.respond(route: "GET /v1/daily/insight", status: 500, body: failure)

        // When
        chooseAnswers(["Мужской", "Интроверт", "Миротворец", "Рациональный", "Планируете", "Стабильность"])
        tapButton("Далее")
        tapButton("Разрешить")

        // Then
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "AI failure blocked onboarding")
        XCTAssertTrue(text(part: serverError).firstMatch.waitForExistence(timeout: 15), "no content error on the main screen")
        XCTAssertFalse(server.requests.contains("GET /v1/daily/tip"), "a locked profile requested a hidden tip")
    }

    func test_consentFailure_staysOnLoadingScreen_andRetryFinishes() throws {
        let user = try sampleUser(["hasAIConsent": false])
        server.respond(route: "PATCH /v1/auth/profileInfo", body: try profileBody(user: user))
        server.respond(route: "POST /v1/auth/aiConsent", status: 500, body: try failingBody(serverError))
        try openProfileQuestions()
        chooseAnswers(["Мужской", "Интроверт", "Миротворец", "Рациональный", "Планируете", "Стабильность"])
        tapButton("Далее")
        tapButton("Разрешить")

        XCTAssertTrue(text(part: serverError).waitForExistence(timeout: 15), "consent error was hidden")
        XCTAssertFalse(app.tabBars.firstMatch.exists)

        server.respond(route: "POST /v1/auth/aiConsent", body: try json(sampleUser()))
        tapButton("Повторить")
        assertOnMainScreen()
    }

    func test_registration_showsAlertsForWrongInput() throws {
        // Given
        try openNameStep()

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

    func test_birthTimeSwitch_showsTheTimeField() throws {
        // Given
        try openNameStep()
        XCTAssertFalse(text("Время рождения").exists)

        // When
        app.switches["Я знаю время рождения"].switches.firstMatch.tap()

        // Then
        XCTAssertTrue(text("Время рождения").waitForExistence(timeout: 3), "the time field did not appear")
    }

    func test_profileQuestions_withoutAnswers_showAlert() throws {
        // Given
        try openProfileQuestions()

        // When
        tapButton("Далее")

        // Then
        XCTAssertEqual(alertText(), "Ответьте на все вопросы")
    }

    func test_decliningAIConsent_locksTheScreen_andAllowingUnlocksIt() throws {
        // Given
        let user = try sampleUser(["hasAIConsent": false])
        server.respond(route: "PATCH /v1/auth/profileInfo", body: try profileBody(user: user))
        try openProfileQuestions()
        chooseAnswers(["Мужской", "Интроверт", "Миротворец", "Рациональный", "Планируете", "Стабильность"])
        tapButton("Далее")

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

    func test_termsLink_opensInSafari() throws {
        // Given
        try openNameStep()
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
        server.respond(route: "POST /v1/auth/signIn", body: try authBody(user: user))
        try launchOnWelcome()
        signIn()
        XCTAssertTrue(text("Когда вы родились?").waitForExistence(timeout: 15), "the date step did not open")
        app.terminate()
        app.launch()
        let arrow = app.buttons["chevron.left"].firstMatch
        XCTAssertTrue(arrow.waitForExistence(timeout: 15), "the date step did not reopen")

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
