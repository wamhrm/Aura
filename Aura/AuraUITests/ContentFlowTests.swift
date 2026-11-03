//
//  ContentFlowTests.swift
//  AuraUITests
//

import XCTest

final class ContentFlowTests: FlowTestCase {
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

    func test_whenServerFails_screensShowTheError_andRetryRecovers() throws {
        // Given
        let body = try failingBody(serverError)
        for route in ["GET /v1/daily/insight", "GET /v1/daily/tip", "GET /v1/horoscope/current", "GET /v1/history"] {
            server.respond(to: route, status: 500, body: body)
        }

        // When
        try launchSignedIn()

        // Then
        XCTAssertTrue(retryButtons.firstMatch.waitForExistence(timeout: 15), "no retry on the main screen")
        XCTAssertEqual(app.alerts.count, 0)

        openHistory()
        XCTAssertTrue(text(serverError).waitForExistence(timeout: 5), "no error in the history")
        XCTAssertFalse(text("История пуста").exists)

        openProfile()
        XCTAssertTrue(text(containing: serverError).waitForExistence(timeout: 5), "no error in the profile")
        XCTAssertFalse(text(containing: "Пройдите тесты").exists)

        // When
        try restoreContentResponses()
        tapButton("Повторить")

        // Then
        XCTAssertTrue(text(containing: "Пройдите тесты").waitForExistence(timeout: 10), "the profile did not recover")

        openHistory()
        tapButton("Повторить")
        XCTAssertTrue(text("История пуста").waitForExistence(timeout: 10), "the history did not recover")

        openHome()
        while retryButtons.firstMatch.exists {
            retryButtons.firstMatch.tap()
            sleep(1)
        }
        assertOnMainScreen()
        XCTAssertTrue(app.buttons["Читать"].firstMatch.waitForExistence(timeout: 10), "the horoscope did not recover")
    }

    func test_history_opensAnEntry_andDeletesIt() throws {
        // Given
        try setHistoryWithPersonalityResult()
        try launchSignedIn()
        openHistory()
        let entry = button(containing: "Тихий стратег")
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "the entry is not in the history")

        // When
        entry.tap()

        // Then
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 10), "the entry did not open")

        // When
        goBack()
        server.respond(to: "GET /v1/history", body: Data("[]".utf8))
        entry.press(forDuration: 1.5)
        tapButton("Удалить")

        // Then
        XCTAssertTrue(entry.waitForNonExistence(timeout: 5), "the entry was not removed")
        XCTAssertTrue(server.requests.contains("DELETE /v1/history/:historyID"))
    }

    func test_profile_showsOnlyRealResults_andEditingSaves() throws {
        // Given
        try setHistoryWithPersonalityResult()
        try launchSignedIn()

        // When
        openProfile()

        // Then
        XCTAssertTrue(text("Общий персональный вывод").waitForExistence(timeout: 10), "the result is not in the profile")
        XCTAssertTrue(text("Социальный фильтр").exists)
        XCTAssertFalse(text("Глубина связи").exists)

        // When
        app.buttons["gearshape"].firstMatch.tap()
        tapButton("Обновить информацию о себе")
        XCTAssertTrue(app.navigationBars["О вас"].waitForExistence(timeout: 5), "the form did not open")
        tapButton("Готово")

        // Then
        XCTAssertTrue(app.navigationBars["Профиль"].waitForExistence(timeout: 10), "the form did not close")
        XCTAssertTrue(server.requests.contains("PATCH /v1/auth/profileInfo"))
    }

    // MARK: - Helpers
    private func restoreContentResponses() throws {
        server.respond(to: "GET /v1/daily/insight", body: try ContractFile.data("daily.json"))
        server.respond(to: "GET /v1/daily/tip", body: try ContractFile.data("daily.json"))
        server.respond(to: "GET /v1/horoscope/current", body: try ContractFile.data("horoscope.json"))
        server.respond(to: "GET /v1/history", body: Data("[]".utf8))
    }

    private func setHistoryWithPersonalityResult() throws {
        let list = try XCTUnwrap(JSONSerialization.jsonObject(with: try ContractFile.data("history_list.json")) as? [[String: Any]])
        var entry = try XCTUnwrap(list.first { $0["kind"] as? String == "personality" })
        let listData = try JSONSerialization.data(withJSONObject: [entry])

        entry["personalityResult"] = try ContractFile.object("personality_result.json")

        server.respond(to: "GET /v1/history", body: listData)
        server.respond(to: "GET /v1/history/:historyID", body: try JSONSerialization.data(withJSONObject: entry))
        server.respond(to: "DELETE /v1/history/:historyID", status: 204)
    }
}
