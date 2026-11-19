//
//  ProfileUITests.swift
//  AuraUITests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest

final class ProfileUITests: AuraUITestCase {
    func test_changingLanguage_refreshesCurrentContentInBothDirections() throws {
        try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        try launchSignedIn()
        assertOnMainScreen()
        openSettings()

        let horoscopeRoute = "GET /v1/horoscope/current"
        let insightRoute = "GET /v1/daily/insight"
        let tipRoute = "GET /v1/daily/tip"
        let routes = [horoscopeRoute, insightRoute, tipRoute]
        let russianSettings = app.navigationBars["Настройки"]
        let englishSettings = app.navigationBars["Settings"]
        XCTAssertTrue(app.buttons["Синий"].firstMatch.exists)
        var newDaily = try SampleResponses.object(SampleResponses.daily)
        newDaily["text"] = "An English daily tip"
        server.respond(route: tipRoute, body: try json(newDaily))
        newDaily["text"] = "An English daily insight"
        server.respond(route: insightRoute, body: try json(newDaily))
        var newHoroscope = try SampleResponses.object(SampleResponses.horoscope)
        newHoroscope["description"] = "An English horoscope"
        server.respond(route: horoscopeRoute, body: try json(newHoroscope))

        tapButton("Как в iPhone")
        tapButton("English")
        XCTAssertTrue(englishSettings.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Blue"].firstMatch.exists)
        englishSettings.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.firstMatch.buttons["History"].exists)
        XCTAssertTrue(text(part: "May").exists)
        XCTAssertTrue(text("An English daily tip").waitForExistence(timeout: 10))
        XCTAssertTrue(text("Общий персональный вывод").exists)
        app.tabBars.firstMatch.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(text("An English daily insight").waitForExistence(timeout: 10))
        XCTAssertTrue(text("An English horoscope").waitForExistence(timeout: 10))
        for route in routes {
            XCTAssertEqual(server.languages(for: route).last, "en", route)
        }

        app.tabBars.firstMatch.buttons.element(boundBy: 3).tap()
        tapButton("gearshape")
        server.respond(route: horoscopeRoute, body: SampleResponses.horoscope)
        server.respond(route: insightRoute, body: SampleResponses.daily)
        server.respond(route: tipRoute, body: SampleResponses.daily)
        tapButton("English")
        tapButton("Русский")
        XCTAssertTrue(russianSettings.waitForExistence(timeout: 5))
        russianSettings.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Профиль"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.firstMatch.buttons["История"].exists)
        XCTAssertTrue(text(part: "13 мая 2000").exists)
        XCTAssertTrue(text(dailyText).waitForExistence(timeout: 10))
        app.tabBars.firstMatch.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
        assertOnMainScreen()
        XCTAssertTrue(text("Краткий гороскоп на неделю").waitForExistence(timeout: 10))
        for route in routes {
            XCTAssertEqual(server.languages(for: route).last, "ru", route)
        }
    }

    func test_withResults_profileShowsCurrentSign_andSavedResult() throws {
        // Given
        try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        try launchSignedIn(user: try sampleUser(["dateOfBirth": "20.01.1990"]))

        // When
        openProfile()

        // Then
        XCTAssertTrue(text("Общий персональный вывод").waitForExistence(timeout: 10), "the result is not in the profile")
        XCTAssertTrue(text("Водолей").exists, "the header uses the old test's sign instead of the current birth date")
        XCTAssertTrue(text("Социальный фильтр").exists)
        XCTAssertFalse(text("Глубина связи").exists)
    }

    func test_whenServerFails_showsTheError_andRetryRecovers() throws {
        // Given
        server.respond(route: "GET /v1/history", status: 500, body: try failingBody(serverError))
        try launchSignedIn()
        openProfile()
        XCTAssertTrue(text(part: serverError).waitForExistence(timeout: 10), "no error in the profile")

        // When
        server.respond(route: "GET /v1/history", body: Data("[]".utf8))
        tapButton("Повторить")

        // Then
        XCTAssertTrue(text(part: "Пройдите тесты").waitForExistence(timeout: 10), "the profile did not recover")
        XCTAssertFalse(text(part: "Интуитивный креатор").exists)
    }

    func test_editForm_whenSavingFails_keepsInput_andAllowsRetry() throws {
        let saveProfile = "PATCH /v1/auth/profileInfo"
        server.respond(route: saveProfile, status: 500, body: try failingBody(serverError))
        try launchSignedIn()
        openSettings()
        tapButton("Обновить информацию о себе")
        XCTAssertTrue(app.navigationBars["О вас"].waitForExistence(timeout: 5), "the form did not open")
        let name = app.textFields["Введите имя"].firstMatch
        fillField(name, text: "-Мария")
        let enteredName = name.value as? String

        tapButton("Готово")

        XCTAssertEqual(alertText(), serverError)
        closeAlert()
        XCTAssertTrue(app.navigationBars["О вас"].exists)
        XCTAssertEqual(name.value as? String, enteredName)

        server.respond(route: saveProfile, body: try profileBody(user: sampleUser()))
        tapButton("Готово")

        XCTAssertTrue(app.navigationBars["Профиль"].waitForExistence(timeout: 10), "the form did not close after retry")
        XCTAssertEqual(server.requests.filter { $0 == saveProfile }.count, 2)
    }

    func test_settings_showLegalLinks_andCloseWithTheCross() throws {
        // Given
        try launchSignedIn()

        // When
        openSettings()

        // Then
        let settings = app.navigationBars["Настройки"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "the settings did not open")
        XCTAssertTrue(app.links["Политика конфиденциальности"].firstMatch.waitForExistence(timeout: 5), "no link to the policy")
        XCTAssertTrue(app.links["Условия использования"].firstMatch.exists, "no link to the terms")

        // When
        settings.buttons.firstMatch.tap()

        // Then
        XCTAssertTrue(settings.waitForNonExistence(timeout: 5), "the settings did not close")
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
        let deleteAccount = "DELETE /v1/auth/account"
        try launchSignedIn()
        openSettings()

        // When it is cancelled
        tapButton("Удалить аккаунт")
        confirmAlert("Отмена")

        // Then
        XCTAssertFalse(server.requests.contains(deleteAccount))

        // When it is confirmed
        tapButton("Удалить аккаунт")
        confirmAlert("Удалить")

        // Then
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15), "did not return to the welcome screen")
        XCTAssertEqual(server.requests.filter { $0 == deleteAccount }.count, 1)
    }

    func test_deleteAccount_whenServerFails_showsAlert() throws {
        // Given
        server.respond(route: "DELETE /v1/auth/account", status: 500, body: try failingBody(serverError))
        try launchSignedIn()
        openSettings()

        // When
        tapButton("Удалить аккаунт")
        confirmAlert("Удалить")

        // Then
        XCTAssertEqual(alertText(), "Не удалось удалить аккаунт")
    }
}
