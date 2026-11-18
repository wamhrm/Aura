//
//  AuraUITestCase.swift
//  AuraUITests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest

@MainActor
class AuraUITestCase: XCTestCase {
    private(set) var server: MockServer!
    private(set) var app: XCUIApplication!

    let email = "anna@example.test"
    let password = "password-1"
    let dailyText = "Сегодня вы спокойнее, чем кажется"
    let serverError = "Сервис временно недоступен. Попробуйте позже"

    override func setUp() async throws {
        continueAfterFailure = false

        server = try MockServer()
        try setDefaultResponses()

        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ru)"]
        app.launchEnvironment["AURA_BASE_URL"] = server.baseURL
        app.launchEnvironment["AURA_UI_TEST_ID"] = UUID().uuidString
    }

    override func tearDown() async throws {
        app.terminate()
        server.stop()
    }

    // MARK: - Server answers
    private func setDefaultResponses() throws {
        let user = try sampleUser()

        server.respond(route: "GET /v1/auth/me", body: try json(user))
        server.respond(route: "POST /v1/auth/createAccount", status: 201, body: try authBody(user: newUser()))
        server.respond(route: "POST /v1/auth/email/available", status: 204)
        server.respond(route: "POST /v1/auth/signIn", body: try authBody(user: user))
        server.respond(route: "POST /v1/auth/password/forgot", status: 204)
        server.respond(route: "POST /v1/auth/password/reset", body: try authBody(user: user))
        server.respond(route: "POST /v1/auth/logout", status: 204)
        server.respond(route: "DELETE /v1/auth/account", status: 204)
        server.respond(route: "PATCH /v1/auth/profileInfo", body: try profileBody(user: user))
        server.respond(route: "POST /v1/auth/aiConsent", body: try json(user))
        server.respond(route: "GET /v1/horoscope/current", body: SampleResponses.horoscope)
        server.respond(route: "GET /v1/daily/insight", body: SampleResponses.daily)
        server.respond(route: "GET /v1/daily/tip", body: SampleResponses.daily)
        server.respond(route: "GET /v1/history", body: Data("[]".utf8))
        server.respond(route: "POST /v1/history/personality", body: SampleResponses.personalityResult)
        server.respond(route: "POST /v1/history/compatibility", body: SampleResponses.compatibilityResult)
    }

    func json(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }

    func failingBody(_ reason: String) throws -> Data {
        try json(["error": true, "reason": reason])
    }

    func sampleUser(_ changes: [String: Any] = [:]) throws -> [String: Any] {
        let user = try XCTUnwrap(try SampleResponses.object(SampleResponses.auth)["user"] as? [String: Any])
        return user.merging(changes) { _, new in new }
    }

    func newUser() throws -> [String: Any] {
        let user = try sampleUser()
        return ["id": try XCTUnwrap(user["id"]), "name": "Анна", "email": email, "hasAIConsent": false, "isEmailConfirmed": false]
    }

    func authBody(user: [String: Any]) throws -> Data {
        try json(["token": "sample-token", "user": user])
    }

    func profileBody(user: [String: Any]) throws -> Data {
        try json(["user": user, "horoscope": try SampleResponses.object(SampleResponses.horoscope)])
    }

    func setHistory(kind: String, resultKey: String, result: Data) throws {
        let list = try XCTUnwrap(JSONSerialization.jsonObject(with: SampleResponses.historyList) as? [[String: Any]])
        var entry = try XCTUnwrap(list.first { $0["kind"] as? String == kind })

        server.respond(route: "GET /v1/history", body: try json([entry]))

        entry[resultKey] = try SampleResponses.object(result)

        server.respond(route: "GET /v1/history/:historyID", body: try json(entry))
        server.respond(route: "DELETE /v1/history/:historyID", status: 204)
    }

    // MARK: - Launch
    var welcomeButton: XCUIElement {
        app.buttons["У меня уже есть аккаунт"].firstMatch
    }

    func launchOnWelcome() throws {
        app.launch()
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 20), "the welcome screen did not open")
    }

    func launchSignedIn(user: [String: Any]? = nil) throws {
        let user = try user ?? sampleUser()
        server.respond(route: "POST /v1/auth/signIn", body: try authBody(user: user))
        try launchOnWelcome()
        signIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "the main screen did not open")
    }

    func signIn(password: String? = nil) {
        welcomeButton.tap()
        fillField(app.textFields["Электронная почта"].firstMatch, text: email)
        fillField(app.secureTextFields["Пароль"].firstMatch, text: password ?? self.password)
        tapButton("Войти")
    }

    func openSettings() {
        openProfile()
        app.buttons["gearshape"].firstMatch.tap()
    }

    // MARK: - Actions
    func fillField(_ field: XCUIElement, text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 10), "no field \(field.description)")
        field.tap()
        field.typeText(text)
    }

    func tapButton(_ title: String) {
        let button = app.buttons[title].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "no button \(title)")

        for _ in 0..<8 where !button.isHittable {
            app.swipeUp()
        }

        button.tap()
    }

    func chooseAnswers(_ answers: [String]) {
        for answer in answers {
            let chip = text(answer)
            for _ in 0..<5 where !chip.isHittable {
                app.swipeUp()
            }
            chip.tap()
        }
    }

    func scrollUp(element: XCUIElement) {
        for _ in 0..<8 where !element.isHittable {
            app.swipeDown()
        }
    }

    func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
    }

    func confirmAlert(_ button: String) {
        let confirm = app.alerts.buttons[button].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "no alert with \(button)")
        confirm.tap()
        sleep(1)
    }

    func alertText() -> String {
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 15), "no alert")
        return alert.label
    }

    func closeAlert() {
        app.alerts.firstMatch.buttons.firstMatch.tap()
        sleep(1)
    }

    // MARK: - Tabs
    private func openTab(_ index: Int, title: String) {
        let bar = app.navigationBars[title]
        var taps = 0

        repeat {
            taps += 1
            app.tabBars.firstMatch.buttons.element(boundBy: index).tap()
        } while !bar.waitForExistence(timeout: 3) && taps < 5

        XCTAssertTrue(bar.exists, "tab \(title) did not open")
    }

    func openHome() {
        openTab(0, title: "Главная")
    }

    func openCompatibility() {
        openTab(1, title: "Узнать совместимость")
    }

    func openHistory() {
        openTab(2, title: "История тестов")
    }

    func openProfile() {
        openTab(3, title: "Профиль")
    }

    // MARK: - Finding things
    func text(_ value: String) -> XCUIElement {
        app.staticTexts[value].firstMatch
    }

    func text(part: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", part)).firstMatch
    }

    func button(part: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", part)).firstMatch
    }

    func assertOnMainScreen(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text(dailyText).waitForExistence(timeout: 30), "the main screen did not open", file: file, line: line)
    }
}
