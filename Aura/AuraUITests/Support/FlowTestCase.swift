//
//  FlowTestCase.swift
//  AuraUITests
//

import XCTest

// Every flow runs the real app against MockServer, which answers from the Contract folder.
// If a text on a screen changes, the helpers below are usually the only place to fix.
@MainActor
class FlowTestCase: XCTestCase {
    private(set) var server: MockServer!
    private(set) var app: XCUIApplication!

    let email = "anna@example.test"
    let password = "password-1"
    let serverError = "Сервис временно недоступен. Попробуйте позже"
    let dailyText = "Сегодня вы спокойнее, чем кажется"

    override func setUp() async throws {
        continueAfterFailure = false

        server = try MockServer()
        try setDefaultResponses()

        app = XCUIApplication()
        app.launchEnvironment["AURA_BASE_URL"] = server.baseURL
    }

    override func tearDown() async throws {
        app.terminate()
        server.stop()
    }

    // MARK: - Responses
    private func setDefaultResponses() throws {
        let auth = try ContractFile.object("auth.json")
        let user = try XCTUnwrap(auth["user"])
        let horoscope = try ContractFile.object("horoscope.json")
        let profileResponse: [String: Any] = ["user": user, "horoscope": horoscope]

        server.respond(to: "POST /v1/auth/createAccount", status: 201, body: try newUserAuth())
        server.respond(to: "POST /v1/auth/signIn", body: try ContractFile.data("auth.json"))
        server.respond(to: "POST /v1/auth/password/forgot", status: 204)
        server.respond(to: "POST /v1/auth/password/reset", body: try ContractFile.data("auth.json"))
        server.respond(to: "POST /v1/auth/logout", status: 204)
        server.respond(to: "DELETE /v1/auth/account", status: 204)
        server.respond(to: "PATCH /v1/auth/profileInfo", body: try JSONSerialization.data(withJSONObject: profileResponse))
        server.respond(to: "POST /v1/auth/aiConsent", body: try JSONSerialization.data(withJSONObject: user))
        server.respond(to: "GET /v1/horoscope/current", body: try ContractFile.data("horoscope.json"))
        server.respond(to: "GET /v1/daily/insight", body: try ContractFile.data("daily.json"))
        server.respond(to: "GET /v1/daily/tip", body: try ContractFile.data("daily.json"))
        server.respond(to: "GET /v1/history", body: Data("[]".utf8))
        server.respond(to: "POST /v1/history/personality", body: try ContractFile.data("personality_result.json"))
        server.respond(to: "POST /v1/history/compatibility", body: try ContractFile.data("compatibility_result.json"))
    }

    // A user who has just registered: no profile answers and no consent yet
    func newUserAuth() throws -> Data {
        var auth = try ContractFile.object("auth.json")
        let user = try XCTUnwrap(auth["user"] as? [String: Any])
        auth["user"] = ["id": user["id"], "name": user["name"], "email": user["email"], "hasAIConsent": false, "isEmailConfirmed": false]
        return try JSONSerialization.data(withJSONObject: auth)
    }

    func newUser() throws -> Data {
        let auth = try XCTUnwrap(JSONSerialization.jsonObject(with: try newUserAuth()) as? [String: Any])
        return try JSONSerialization.data(withJSONObject: try XCTUnwrap(auth["user"]))
    }

    func completeUser() throws -> Data {
        try JSONSerialization.data(withJSONObject: try XCTUnwrap(try ContractFile.object("auth.json")["user"]))
    }

    // A registered user who answered everything but has not confirmed the email yet
    func unconfirmedUser() throws -> [String: Any] {
        var user = try XCTUnwrap(try ContractFile.object("auth.json")["user"] as? [String: Any])
        user["isEmailConfirmed"] = false
        return user
    }

    func failingBody(_ reason: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["error": true, "reason": reason])
    }

    // MARK: - Launch and sign-in
    var welcomeButton: XCUIElement {
        app.buttons["У меня уже есть аккаунт"].firstMatch
    }

    // A session left by an earlier test ends at launch, so every test starts on the welcome screen
    func launchOnWelcome() throws {
        server.respond(to: "GET /v1/auth/me", status: 401, body: try failingBody("Неверный токен"))
        app.launch()
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 20), "the welcome screen did not open")
        server.respond(to: "GET /v1/auth/me", body: try completeUser())
    }

    func launchSignedIn() throws {
        try launchOnWelcome()
        signIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "the main screen did not open")
    }

    func signIn() {
        welcomeButton.tap()
        fillField(app.textFields["Электронная почта"].firstMatch, with: email)
        fillField(app.secureTextFields["Пароль"].firstMatch, with: password)
        tapButton("Войти")
    }

    func signOut() {
        openProfile()
        app.buttons["gearshape"].firstMatch.tap()
        tapButton("Выйти")
        confirmAlert("Выйти")
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 15), "did not return to the welcome screen")
    }

    // MARK: - Actions
    func fillField(_ field: XCUIElement, with text: String) {
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

    // The onboarding arrow reacts to a tap on the chevron itself, the middle of its frame is empty
    func tapOnboardingBackArrow() {
        let arrow = app.buttons["chevron.left"].firstMatch
        XCTAssertTrue(arrow.waitForExistence(timeout: 10), "no back arrow")
        arrow.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.4)).tap()
    }

    func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
    }

    func confirmAlert(_ button: String) {
        let confirm = app.alerts.buttons[button].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "no alert with \(button)")
        confirm.tap()
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
    // The system "Save Password?" sheet swallows the next tap, so a tab is tapped until its screen opens
    private func openTab(_ index: Int, showing title: String) {
        let bar = app.navigationBars[title]
        var taps = 0

        repeat {
            taps += 1
            app.tabBars.firstMatch.buttons.element(boundBy: index).tap()
        } while !bar.waitForExistence(timeout: 3) && taps < 5

        XCTAssertTrue(bar.exists, "tab \(title) did not open")
    }

    func openHome() {
        openTab(0, showing: "Главная")
    }

    func openCompatibility() {
        openTab(1, showing: "Узнать совместимость")
    }

    func openHistory() {
        openTab(2, showing: "История тестов")
    }

    func openProfile() {
        openTab(3, showing: "Профиль")
    }

    // MARK: - Checks
    func text(_ value: String) -> XCUIElement {
        app.staticTexts[value].firstMatch
    }

    func text(containing part: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", part)).firstMatch
    }

    func button(containing part: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", part)).firstMatch
    }

    var retryButtons: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label == %@", "Повторить"))
    }

    func assertOnMainScreen(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text(dailyText).waitForExistence(timeout: 30), "the main screen did not open", file: file, line: line)
    }
}
