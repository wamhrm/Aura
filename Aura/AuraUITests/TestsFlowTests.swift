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
        fillField(app.textFields["День/Месяц/Год"].firstMatch, with: "01012015")
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
