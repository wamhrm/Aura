//
//  HomeUITests.swift
//  AuraUITests
//

import XCTest

final class HomeUITests: AuraUITestCase {
    func test_mainScreen_showsInsight_andOpensHoroscope() throws {
        // Given
        try launchSignedIn()
        assertOnMainScreen()

        // When
        tapButton("Читать")

        // Then
        XCTAssertTrue(app.navigationBars["Мой гороскоп"].waitForExistence(timeout: 5), "the horoscope did not open")
        XCTAssertTrue(text(containing: "Краткий гороскоп на неделю").exists)
        XCTAssertTrue(text("Любовь").exists)
    }

    func test_compatibilityBanner_opensItsTab() throws {
        // Given
        try launchSignedIn()
        assertOnMainScreen()

        // When
        tapButton("Проверить совместимость")

        // Then
        XCTAssertTrue(app.navigationBars["Узнать совместимость"].waitForExistence(timeout: 5), "the tab did not open")
    }

    func test_allTestsScreen_showsEveryTest() throws {
        // Given
        try launchSignedIn()

        // When
        tapButton("Все тесты")

        // Then
        XCTAssertTrue(app.navigationBars["Проверить себя"].waitForExistence(timeout: 5), "the screen did not open")

        for title in ["Астрологический портрет", "Поведенческие паттерны", "Стиль принятия решений", "Стиль привязанности", "Идеальный партнер", "Язык любви"] {
            XCTAssertTrue(text(title).exists, "no test \(title)")
        }
    }

    func test_tests_canBeSelected_andKeepTheMinimum() throws {
        // Given
        try launchSignedIn()
        let thirdTest = "Стиль принятия решений"
        XCTAssertTrue(text(thirdTest).waitForExistence(timeout: 15), "the tests are not on the main screen")

        // When the third test is selected in its row
        button(containing: thirdTest).buttons.firstMatch.tap()
        text(thirdTest).tap()

        // Then its details screen knows about it
        XCTAssertTrue(app.buttons["Убрать"].firstMatch.waitForExistence(timeout: 5), "the test was not selected")

        // When it is removed on the details screen
        tapButton("Убрать")

        // Then
        XCTAssertTrue(app.buttons["Выбрать"].firstMatch.waitForExistence(timeout: 5), "the test was not removed")

        // When one of the last two tests is removed
        goBack()
        text("Астрологический портрет").tap()
        tapButton("Убрать")

        // Then
        XCTAssertEqual(alertText(), "Нельзя выбрать меньше 2 тестов")
        closeAlert()
        XCTAssertTrue(app.buttons["Убрать"].firstMatch.exists, "the test was removed below the minimum")
    }

    func test_personalityTest_showsTheResult() throws {
        // Given
        try launchSignedIn()

        // When
        tapButton("Проверить себя")

        // Then
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 15), "the result did not open")
        XCTAssertTrue(text("Тихий стратег").exists)
        XCTAssertTrue(text("Черты вашего знака").exists)
    }

    func test_personalityTest_whenAIFails_showsAlert_andRepeatWorks() throws {
        // Given
        server.respond(to: "POST /v1/history/personality", status: 502, body: try failingBody(serverError))
        try launchSignedIn()

        // When
        tapButton("Проверить себя")

        // Then
        XCTAssertEqual(alertText(), serverError)

        // When
        closeAlert()
        server.respond(to: "POST /v1/history/personality", body: SampleResponses.personalityResult)
        tapButton("Проверить себя")

        // Then
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 15), "the result did not open")
    }

    func test_personalityTest_withoutConfirmedEmail_asksForTheCode_andThenWorks() throws {
        // Given
        server.respond(to: "POST /v1/auth/email/sendCode", status: 204)
        server.respond(to: "POST /v1/auth/email/confirm", status: 400, body: try failingBody("Неверный код"))
        try launchSignedIn(user: try sampleUser(["isEmailConfirmed": false]))

        // When
        tapButton("Проверить себя")

        // Then
        XCTAssertTrue(app.navigationBars["Подтвердите почту"].waitForExistence(timeout: 5), "the sheet did not open")

        // When a wrong code is entered
        tapButton("Подтвердить")
        fillField(app.textFields["Код из 6 цифр"].firstMatch, with: "000000")
        tapButton("Проверить код")

        // Then
        XCTAssertEqual(alertText(), "Неверный код")
        closeAlert()

        // When the right code is entered
        server.respond(to: "POST /v1/auth/email/confirm", body: try json(try sampleUser()))
        tapButton("Проверить код")

        // Then the sheet closes and the test works
        XCTAssertTrue(app.navigationBars["Подтвердите почту"].waitForNonExistence(timeout: 10), "the sheet did not close")
        tapButton("Проверить себя")
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 15), "the result did not open")
    }

    func test_whenServerFails_showsRetry_andRetryRecovers() throws {
        // Given
        let body = try failingBody(serverError)
        server.respond(to: "GET /v1/daily/insight", status: 500, body: body)
        server.respond(to: "GET /v1/horoscope/current", status: 500, body: body)
        try launchSignedIn()
        let retry = app.buttons.matching(NSPredicate(format: "label == %@", "Повторить")).firstMatch
        XCTAssertTrue(retry.waitForExistence(timeout: 15), "no retry on the main screen")

        // When
        server.respond(to: "GET /v1/daily/insight", body: SampleResponses.daily)
        server.respond(to: "GET /v1/horoscope/current", body: SampleResponses.horoscope)

        for _ in 0..<3 where retry.exists {
            retry.tap()
            sleep(1)
        }
        XCTAssertFalse(retry.exists, "the retry controls did not disappear")

        // Then
        assertOnMainScreen()
        XCTAssertTrue(app.buttons["Читать"].firstMatch.waitForExistence(timeout: 10), "the horoscope did not recover")
    }
}
