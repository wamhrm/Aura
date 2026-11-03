//
//  TestsFlowTests.swift
//  AuraUITests
//

import XCTest

final class TestsFlowTests: FlowTestCase {
    func test_personalityTests_canBeSelected_andKeepTheMinimum() throws {
        // Given
        try launchSignedIn()
        let thirdTest = "Стиль принятия решений"
        XCTAssertTrue(text(thirdTest).waitForExistence(timeout: 15), "the tests are not on the main screen")

        // When the third test is selected in its row
        button(containing: thirdTest).buttons.firstMatch.tap()
        text(thirdTest).tap()

        // Then
        XCTAssertTrue(app.buttons["Убрать"].firstMatch.waitForExistence(timeout: 5), "the test was not selected")

        // When it is removed on its details screen
        tapButton("Убрать")

        // Then
        XCTAssertTrue(app.buttons["Выбрать"].firstMatch.waitForExistence(timeout: 5), "the test was not removed")

        // When one of the last two tests is removed
        goBack()
        text("Астрология").tap()
        tapButton("Убрать")

        // Then
        XCTAssertEqual(alertText(), "Нельзя выбрать меньше 2 тестов")
        closeAlert()
        XCTAssertTrue(app.buttons["Убрать"].firstMatch.exists, "the test was removed below the minimum")
    }

    func test_tests_whenEmailNotConfirmed_askForTheCode_andThenWork() throws {
        // Given
        var auth = try ContractFile.object("auth.json")
        auth["user"] = try unconfirmedUser()
        server.respond(to: "POST /v1/auth/signIn", body: try JSONSerialization.data(withJSONObject: auth))
        server.respond(to: "POST /v1/auth/email/sendCode", status: 204)
        server.respond(to: "POST /v1/auth/email/confirm", status: 400, body: try failingBody("Неверный код"))
        try launchOnWelcome()
        server.respond(to: "GET /v1/auth/me", body: try JSONSerialization.data(withJSONObject: try unconfirmedUser()))
        signIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "the main screen did not open")

        // When the test on the main screen is started
        tapButton("Проверить себя")

        // Then
        XCTAssertTrue(app.navigationBars["Подтвердите почту"].waitForExistence(timeout: 5), "the sheet did not open")
        XCTAssertFalse(server.requests.contains("POST /v1/history/personality"))

        // When the code is sent, the sheet is closed and the compatibility test is started
        tapButton("Подтвердить")
        XCTAssertTrue(app.textFields["Код из 6 цифр"].firstMatch.waitForExistence(timeout: 10), "no code field")
        app.navigationBars["Подтвердите почту"].buttons.firstMatch.tap()
        openCompatibility()
        tapButton("Узнать совместимость")

        // Then
        XCTAssertTrue(app.navigationBars["Подтвердите почту"].waitForExistence(timeout: 5), "the sheet did not open")

        // When a new code is refused because the last one is too recent
        let tooSoon = "Код уже отправлен. Запросить новый можно через минуту"
        server.respond(to: "POST /v1/auth/email/sendCode", status: 429, body: try failingBody(tooSoon))
        tapButton("Подтвердить")

        // Then the code from the first email can still be entered
        XCTAssertEqual(alertText(), tooSoon)
        closeAlert()

        // When a wrong code is entered
        fillField(app.textFields["Код из 6 цифр"].firstMatch, with: "000000")
        tapButton("Проверить код")

        // Then
        XCTAssertEqual(alertText(), "Неверный код")
        closeAlert()

        // When the right code is entered
        server.respond(to: "POST /v1/auth/email/confirm", body: try completeUser())
        tapButton("Проверить код")

        // Then
        XCTAssertTrue(app.navigationBars["Подтвердите почту"].waitForNonExistence(timeout: 10), "the sheet did not close")
        XCTAssertTrue(server.requests.contains("POST /v1/auth/email/sendCode"))

        // When
        openHome()
        tapButton("Проверить себя")

        // Then
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 15), "the result did not open")
    }

    func test_personalityTest_showsTheAIResult() throws {
        // Given
        try launchSignedIn()

        // When
        tapButton("Проверить себя")

        // Then
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 15), "the result did not open")
        XCTAssertTrue(text("Тихий стратег").exists)
        XCTAssertTrue(text("Анализ натальной карты").exists)
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
        server.respond(to: "POST /v1/history/personality", body: try ContractFile.data("personality_result.json"))
        tapButton("Проверить себя")

        // Then
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 15), "the result did not open")
    }

    func test_compatibility_checksTheForm_andShowsTheAIResult() throws {
        // Given
        try launchSignedIn()
        openCompatibility()

        // When the name is empty
        tapButton("Узнать совместимость")

        // Then
        XCTAssertTrue(alertText().contains("Имя партнёра"))
        closeAlert()

        // When the server refuses the partner
        let refusal = "Партнёру должно быть не меньше 16 лет"
        server.respond(to: "POST /v1/history/compatibility", status: 400, body: try failingBody(refusal))
        for _ in 0..<4 where !app.textFields["Введите имя"].firstMatch.isHittable {
            app.swipeDown()
        }
        fillField(app.textFields["Введите имя"].firstMatch, with: "Иван")
        app.swipeUp()
        tapButton("Узнать совместимость")

        // Then
        XCTAssertEqual(alertText(), refusal)
        closeAlert()

        // When the server accepts
        server.respond(to: "POST /v1/history/compatibility", body: try ContractFile.data("compatibility_result.json"))
        tapButton("Узнать совместимость")

        // Then
        XCTAssertTrue(app.navigationBars["Результат теста на совместимость"].waitForExistence(timeout: 15), "the result did not open")
        XCTAssertTrue(text("Спокойный союз").exists)
    }
}
