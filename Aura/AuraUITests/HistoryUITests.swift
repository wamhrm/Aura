//
//  HistoryUITests.swift
//  AuraUITests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest

final class HistoryUITests: AuraUITestCase {
    func test_personalityEntry_showsItsDate_andOpens() throws {
        // Given
        try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        try launchSignedIn()
        openHistory()
        let entry = button(part: "Тихий стратег")
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "the entry is not in the history")
        XCTAssertTrue(text(part: "ноября 2026").exists, "the entry has no date")

        // When
        entry.tap()

        // Then
        XCTAssertTrue(app.navigationBars["Результат персонального теста"].waitForExistence(timeout: 10), "the entry did not open")
    }

    func test_compatibilityEntry_opens() throws {
        // Given
        try setHistory(kind: "compatibility", resultKey: "compatibilityResult", result: SampleResponses.compatibilityResult)
        try launchSignedIn()
        openHistory()
        let entry = button(part: "Иван")
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "the entry is not in the history")
        let formattedScore = "64\u{00a0}%"
        XCTAssertTrue(text(formattedScore).exists, "the history should show a localized percentage")

        // When
        entry.tap()

        // Then
        XCTAssertTrue(app.navigationBars["Результат теста на совместимость"].waitForExistence(timeout: 10), "the entry did not open")
        XCTAssertTrue(text(formattedScore).exists, "the result should show the same localized percentage")
    }

    func test_delete_asksFirst_andRemovesTheEntry() throws {
        // Given
        let path = try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        try launchSignedIn()
        openHistory()
        let entry = button(part: "Тихий стратег")
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "the entry is not in the history")

        // When the deletion is cancelled
        entry.press(forDuration: 1.5)
        tapButton("Удалить")
        confirmAlert("Отмена")

        // Then
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "the entry was removed without a confirmation")
        XCTAssertFalse(server.requests.contains { $0.hasPrefix("DELETE /v1/history/") })

        // When it is confirmed
        server.respond(route: "GET /v1/history", body: Data("[]".utf8))
        entry.press(forDuration: 1.5)
        tapButton("Удалить")
        confirmAlert("Удалить")

        // Then
        XCTAssertTrue(entry.waitForNonExistence(timeout: 5), "the entry was not removed")
        XCTAssertEqual(server.requests.filter { $0 == "DELETE \(path)" }.count, 1)
    }

    func test_whenServerFails_showsTheError_andRetryRecovers() throws {
        // Given
        server.respond(route: "GET /v1/history", status: 500, body: try failingBody(serverError))
        try launchSignedIn()
        openHistory()
        XCTAssertTrue(text(serverError).waitForExistence(timeout: 10), "no error in the history")

        // When
        server.respond(route: "GET /v1/history", body: Data("[]".utf8))
        tapButton("Повторить")

        // Then
        XCTAssertTrue(text("История пуста").waitForExistence(timeout: 10), "the history did not recover")
    }
}
