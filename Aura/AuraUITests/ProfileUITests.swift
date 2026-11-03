//
//  ProfileUITests.swift
//  AuraUITests
//

import XCTest

final class ProfileUITests: AuraUITestCase {
    func test_withoutResults_profileAsksToTakeTests() throws {
        // Given
        try launchSignedIn()

        // When
        openProfile()

        // Then
        XCTAssertTrue(text(containing: "Пройдите тесты").waitForExistence(timeout: 10), "no prompt to take tests")
    }

    func test_withResults_profileShowsOnlyThem() throws {
        // Given
        try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        try launchSignedIn()

        // When
        openProfile()

        // Then
        XCTAssertTrue(text("Общий персональный вывод").waitForExistence(timeout: 10), "the result is not in the profile")
        XCTAssertTrue(text("Социальный фильтр").exists)
        XCTAssertFalse(text("Глубина связи").exists)
    }

    func test_whenServerFails_showsTheError_andRetryRecovers() throws {
        // Given
        server.respond(to: "GET /v1/history", status: 500, body: try failingBody(serverError))
        try launchSignedIn()
        openProfile()
        XCTAssertTrue(text(containing: serverError).waitForExistence(timeout: 10), "no error in the profile")

        // When
        server.respond(to: "GET /v1/history", body: Data("[]".utf8))
        tapButton("Повторить")

        // Then
        XCTAssertTrue(text(containing: "Пройдите тесты").waitForExistence(timeout: 10), "the profile did not recover")
    }

    func test_editForm_savesAndCloses() throws {
        // Given
        try launchSignedIn()
        openSettings()
        tapButton("Обновить информацию о себе")
        XCTAssertTrue(app.navigationBars["О вас"].waitForExistence(timeout: 5), "the form did not open")

        // When
        fillField(app.textFields["Введите имя"].firstMatch, with: "-Мария")
        tapButton("Готово")

        // Then
        XCTAssertTrue(app.navigationBars["Профиль"].waitForExistence(timeout: 10), "the form did not close")
        XCTAssertTrue(server.requests.contains("PATCH /v1/auth/profileInfo"))
    }

    func test_settings_closeWithTheCross() throws {
        // Given
        try launchSignedIn()
        openSettings()
        XCTAssertTrue(app.navigationBars["Настройки"].waitForExistence(timeout: 5), "the settings did not open")

        // When
        app.navigationBars["Настройки"].buttons.firstMatch.tap()

        // Then
        XCTAssertTrue(app.navigationBars["Настройки"].waitForNonExistence(timeout: 5), "the settings did not close")
    }

    func test_settings_showLegalLinks() throws {
        // Given
        try launchSignedIn()

        // When
        openSettings()

        // Then
        XCTAssertTrue(app.links["Политика конфиденциальности"].firstMatch.waitForExistence(timeout: 5), "no link to the policy")
        XCTAssertTrue(app.links["Условия использования"].firstMatch.exists, "no link to the terms")
    }

    func test_signOut_asksFirst_andReturnsToWelcome() throws {
        // Given
        try launchSignedIn()
        openSettings()

        // When it is cancelled
        tapButton("Выйти")
        confirmAlert("Отмена")

        // Then
        XCTAssertTrue(app.navigationBars["Настройки"].exists)

        // When it is confirmed
        tapButton("Выйти")
        confirmAlert("Выйти")

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15), "did not return to the welcome screen")
    }

    func test_deleteAccount_asksFirst_andReturnsToWelcome() throws {
        // Given
        try launchSignedIn()
        openSettings()

        // When it is cancelled
        tapButton("Удалить аккаунт")
        confirmAlert("Отмена")

        // Then
        XCTAssertFalse(server.requests.contains("DELETE /v1/auth/account"))

        // When it is confirmed
        tapButton("Удалить аккаунт")
        confirmAlert("Удалить")

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15), "did not return to the welcome screen")
    }

    func test_deleteAccount_whenServerFails_showsAlert() throws {
        // Given
        server.respond(to: "DELETE /v1/auth/account", status: 500, body: try failingBody(serverError))
        try launchSignedIn()
        openSettings()

        // When
        tapButton("Удалить аккаунт")
        confirmAlert("Удалить")

        // Then
        XCTAssertEqual(alertText(), "Не удалось удалить аккаунт")
    }
}
