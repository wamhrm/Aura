//
//  HistoryUITests.swift
//  AuraUITests
//

import XCTest

final class HistoryUITests: AuraUITestCase {
    func test_emptyHistory_saysSo() throws {
        // Given
        try launchSignedIn()

        // When
        openHistory()

        // Then
        XCTAssertTrue(text("История пуста").waitForExistence(timeout: 10), "no empty state")
    }

    func test_personalityEntry_showsItsDate_andOpens() throws {
        // Given
        try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        try launchSignedIn()
        openHistory()
        let entry = button(containing: "Тихий стратег")
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "the entry is not in the history")
        XCTAssertTrue(text(containing: "ноября 2026").exists, "the entry has no date")

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
        let entry = button(containing: "Иван")
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "the entry is not in the history")

        // When
        entry.tap()

        // Then
        XCTAssertTrue(app.navigationBars["Результат теста на совместимость"].waitForExistence(timeout: 10), "the entry did not open")
    }

    func test_delete_asksFirst_andRemovesTheEntry() throws {
        // Given
        try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        try launchSignedIn()
        openHistory()
        let entry = button(containing: "Тихий стратег")
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "the entry is not in the history")

        // When the deletion is cancelled
        entry.press(forDuration: 1.5)
        tapButton("Удалить")
        confirmAlert("Отмена")

        // Then
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "the entry was removed without a confirmation")

        // When it is confirmed
        server.respond(to: "GET /v1/history", body: Data("[]".utf8))
        entry.press(forDuration: 1.5)
        tapButton("Удалить")
        confirmAlert("Удалить")

        // Then
        XCTAssertTrue(entry.waitForNonExistence(timeout: 5), "the entry was not removed")
    }

    func test_whenServerFails_showsTheError_andRetryRecovers() throws {
        // Given
        server.respond(to: "GET /v1/history", status: 500, body: try failingBody(serverError))
        try launchSignedIn()
        openHistory()
        XCTAssertTrue(text(serverError).waitForExistence(timeout: 10), "no error in the history")

        // When
        server.respond(to: "GET /v1/history", body: Data("[]".utf8))
        tapButton("Повторить")

        // Then
        XCTAssertTrue(text("История пуста").waitForExistence(timeout: 10), "the history did not recover")
    }
}
