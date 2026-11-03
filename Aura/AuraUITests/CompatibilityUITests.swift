//
//  CompatibilityUITests.swift
//  AuraUITests
//

import XCTest

final class CompatibilityUITests: AuraUITestCase {
    private let answers = ["Интроверт", "Миротворец", "Рациональный", "Планируете", "Стабильность"]

    func test_form_checksTheFields_andShowsTheResult() throws {
        // Given
        try launchSignedIn()
        openCompatibility()

        // When the name is empty
        tapButton("Узнать совместимость")

        // Then
        XCTAssertTrue(alertText().contains("Имя партнёра"))
        closeAlert()

        // When the questions about the partner are not answered
        scrollUp(to: app.textFields["Введите имя"].firstMatch)
        fillField(app.textFields["Введите имя"].firstMatch, with: "Анна-Мария")
        tapButton("Узнать совместимость")

        // Then
        XCTAssertEqual(alertText(), "Ответьте на все вопросы о партнёре")
        closeAlert()

        // When everything is filled in
        scrollUp(to: text("Интроверт"))
        chooseAnswers(answers)
        tapButton("Узнать совместимость")

        // Then
        XCTAssertTrue(app.navigationBars["Результат теста на совместимость"].waitForExistence(timeout: 15), "the result did not open")
        XCTAssertTrue(text("Спокойный союз").exists)
    }

    func test_serverRefusal_showsItsReason() throws {
        // Given
        let refusal = "Партнёру должно быть не меньше 16 лет"
        server.respond(to: "POST /v1/history/compatibility", status: 400, body: try failingBody(refusal))
        try launchSignedIn()
        openCompatibility()
        fillField(app.textFields["Введите имя"].firstMatch, with: "Иван")
        chooseAnswers(answers)

        // When
        tapButton("Узнать совместимость")

        // Then
        XCTAssertEqual(alertText(), refusal)
    }

    func test_afterTheResult_theFormIsEmpty() throws {
        // Given
        try launchSignedIn()
        openCompatibility()
        fillField(app.textFields["Введите имя"].firstMatch, with: "Иван")
        chooseAnswers(answers)
        tapButton("Узнать совместимость")
        XCTAssertTrue(app.navigationBars["Результат теста на совместимость"].waitForExistence(timeout: 15), "the result did not open")

        // When
        goBack()

        // Then
        scrollUp(to: app.textFields["Введите имя"].firstMatch)
        XCTAssertEqual(app.textFields["Введите имя"].firstMatch.value as? String, "")
    }

    func test_birthTimeSwitch_showsTheTimeField() throws {
        // Given
        try launchSignedIn()
        openCompatibility()
        XCTAssertFalse(text("Время").exists)

        // When
        app.switches["Я знаю время рождения"].switches.firstMatch.tap()

        // Then
        XCTAssertTrue(text("Время").waitForExistence(timeout: 3), "the time field did not appear")
    }

    func test_tests_canBeSelected_andKeepTheMinimum() throws {
        // Given
        try launchSignedIn()
        openCompatibility()
        let firstTest = button(containing: "Астрология пары")

        for _ in 0..<8 where !firstTest.isHittable {
            app.swipeUp()
        }

        // When one of the three selected tests is removed
        firstTest.buttons.firstMatch.tap()

        // Then
        XCTAssertEqual(alertText(), "Нельзя выбрать меньше 3 тестов")
        closeAlert()

        // When all tests are selected, one can be removed
        tapButton("Выбрать все")
        firstTest.buttons.firstMatch.tap()

        // Then
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_testDetails_openAndChangeTheSelection() throws {
        // Given
        try launchSignedIn()
        openCompatibility()
        let lastTest = text("Конфликты и примирение")

        for _ in 0..<8 where !lastTest.isHittable {
            app.swipeUp()
        }

        // When
        lastTest.tap()

        // Then
        XCTAssertTrue(app.navigationBars["Конфликты и примирение"].waitForExistence(timeout: 5), "the details did not open")

        // When
        tapButton("Выбрать")

        // Then
        XCTAssertTrue(app.buttons["Убрать"].firstMatch.waitForExistence(timeout: 5), "the test was not selected")
    }

    func test_withoutAIConsent_theFormIsLocked() throws {
        // Given
        let user = try sampleUser(["hasAIConsent": false])
        server.respond(to: "POST /v1/auth/signIn", body: try authBody(user: user))
        try launchOnWelcome()
        server.respond(to: "GET /v1/auth/me", body: try json(user))
        signIn()
        tapButton("Не сейчас")
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 20), "the main screen did not open")

        // When
        openCompatibility()

        // Then
        XCTAssertTrue(text(containing: "Разрешите анализ").waitForExistence(timeout: 5), "no lock on the form")
    }
}
