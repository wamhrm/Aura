//
//  UIAuditScreenshots.swift
//  AuraUITests
//
//  Temporary visual audit. Not part of the product.
//

import XCTest

final class UIAuditScreenshots: AuraUITestCase {
    private var directory: URL?

    override func setUp() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["AURA_CAPTURE_SCREENSHOTS"] == "1",
                          "Set TEST_RUNNER_AURA_CAPTURE_SCREENSHOTS=1 to capture screenshots.")
        try await super.setUp()
        continueAfterFailure = true
    }

    func test_onboarding() {
        launchOnWelcome()
        useWindowDirectory()
        shot("intro-welcome")
        for name in ["horoscope", "daily", "tests"] {
            tapButton("Далее")
            sleep(1)
            shot("intro-\(name)")
        }

        tapButton("У меня уже есть аккаунт")
        shot("sign-in")
        let emailField = app.textFields["Электронная почта"].firstMatch
        emailField.tap()
        sleep(1)
        shot("sign-in-keyboard")

        tapButton("Забыли пароль?")
        shot("reset-request")
        fillField(app.textFields["Электронная почта"].firstMatch, text: email)
        tapButton("Отправить код")
        XCTAssertTrue(text("Введите код из письма").waitForExistence(timeout: 8))
        shot("reset-code")
        app.textFields["Код из 6 цифр"].firstMatch.tap()
        sleep(1)
        shot("reset-code-keyboard")
        audit("reset-keyboard", [
            ("save", app.buttons["Сохранить пароль"].firstMatch),
            ("resend", app.buttons["Отправить код ещё раз"].firstMatch)
        ])

        goBack()
        goBack()
        tapButton("Начать")
        XCTAssertTrue(app.textFields["Имя"].waitForExistence(timeout: 8))
        shot("name-birth")
        app.switches["Я знаю время рождения"].firstMatch.tap()
        sleep(1)
        shot("name-birth-time")
        audit("name-birth", [
            ("next", app.buttons["Далее"].firstMatch),
            ("time", text("Время рождения"))
        ])

        fillField(app.textFields["Имя"].firstMatch, text: "Анна")
        tapButton("Далее")
        XCTAssertTrue(text(part: "электронной почты").waitForExistence(timeout: 8))
        shot("email-step")
        fillField(app.textFields["Электронная почта"].firstMatch, text: email)
        app.textFields["Электронная почта"].firstMatch.tap()
        sleep(1)
        shot("email-keyboard")
        tapButton("Далее")

        XCTAssertTrue(text("Придумайте пароль").waitForExistence(timeout: 8))
        shot("password-step")
        fillField(app.secureTextFields["Пароль"].firstMatch, text: password)
        app.secureTextFields["Пароль"].firstMatch.tap()
        sleep(1)
        shot("password-keyboard")
        tapButton("Далее")

        XCTAssertTrue(text("Расскажите о себе").waitForExistence(timeout: 12))
        shot("psychotype-top")
        app.swipeUp()
        shot("psychotype-mid")
        app.swipeUp()
        shot("psychotype-bottom")
        chooseAnswers(["Мужской", "Интроверт", "Миротворец", "Рациональный", "Планируете", "Стабильность"])
        shot("psychotype-selected")
        tapButton("Далее")
        XCTAssertTrue(text("Анализ с помощью AI").waitForExistence(timeout: 8))
        shot("ai-consent")
        app.swipeUp()
        shot("ai-consent-scrolled")
        audit("ai-consent", [
            ("allow", app.buttons["Разрешить"].firstMatch),
            ("later", app.buttons["Не сейчас"].firstMatch),
            ("policy", app.links["Политика конфиденциальности"].firstMatch)
        ])
    }

    func test_mainAndSheets() throws {
        let longName = "Александра-Мария Константиновна"
        var compatibility = String(decoding: SampleResponses.compatibilityResult, as: UTF8.self)
        compatibility = compatibility.replacingOccurrences(of: "\"userName\": \"Анна\"", with: "\"userName\": \"\(longName)\"")
        compatibility = compatibility.replacingOccurrences(of: "\"partnerName\": \"Иван\"", with: "\"partnerName\": \"\(longName)\"")
        server.respond(route: "POST /v1/history/compatibility", body: Data(compatibility.utf8))

        var history = String(decoding: SampleResponses.historyList, as: UTF8.self)
        history = history.replacingOccurrences(of: "\"partnerName\": \"Иван\"", with: "\"partnerName\": \"\(longName)\"")
        server.respond(route: "GET /v1/history", body: Data(history.utf8))
        try setHistory(kind: "personality", resultKey: "personalityResult", result: SampleResponses.personalityResult)
        server.respond(route: "GET /v1/history", body: Data(history.utf8))

        try launchSignedIn(user: try sampleUser(["name": longName]))
        useWindowDirectory()
        assertOnMainScreen()
        shot("home-top")
        audit("home", [("greeting", text(part: "Здравствуйте"))])
        app.swipeUp()
        shot("home-bottom")

        tapButton("Читать")
        XCTAssertTrue(app.navigationBars["Мой гороскоп"].waitForExistence(timeout: 5))
        shot("horoscope")
        goBack()

        tapButton("Все тесты")
        shot("all-tests")
        text("Стиль привязанности").tap()
        shot("test-details")
        goBack()
        goBack()

        openCompatibility()
        shot("compatibility-top")
        app.swipeUp()
        shot("compatibility-bottom")
        scrollUp(element: app.textFields["Введите имя"].firstMatch)
        fillField(app.textFields["Введите имя"].firstMatch, text: "Иван")
        sleep(1)
        shot("compatibility-keyboard")
        tapButton("Узнать совместимость")
        XCTAssertTrue(app.navigationBars["Результат теста на совместимость"].waitForExistence(timeout: 15))
        shot("compatibility-result")
        let names = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Александра-мария"))
        audit("compatibility-result", [
            ("name-0", names.element(boundBy: 0)),
            ("name-1", names.element(boundBy: 1)),
            ("title", text("Спокойный союз"))
        ])
        app.swipeUp()
        shot("compatibility-result-bottom")
        goBack()

        openHistory()
        shot("history")
        openProfile()
        shot("profile")
        app.swipeUp()
        shot("profile-bottom")
        openSettings()
        XCTAssertTrue(app.navigationBars["Настройки"].waitForExistence(timeout: 5))
        shot("settings")
        audit("settings", [
            ("delete", app.buttons["Удалить аккаунт"].firstMatch),
            ("privacy", app.links["Политика конфиденциальности"].firstMatch),
            ("terms", app.links["Условия использования"].firstMatch)
        ])
        app.navigationBars["Настройки"].buttons.firstMatch.tap()

        openSettings()
        tapButton("Обновить информацию о себе")
        XCTAssertTrue(app.navigationBars["О вас"].waitForExistence(timeout: 5))
        shot("edit-profile")
        app.swipeUp()
        shot("edit-profile-bottom")
    }

    func test_lockedEmailAndErrors() throws {
        server.respond(route: "POST /v1/auth/email/sendCode", status: 204)
        try launchSignedIn(user: try sampleUser([
            "isEmailConfirmed": false,
            "hasAIConsent": false,
            "name": "Анна"
        ]))
        useWindowDirectory()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 20))
        shot("home-locked")
        audit("home-locked", [("allow", app.buttons["Разрешить"].firstMatch)])

        tapButton("Проверить себя")
        XCTAssertTrue(app.navigationBars["Подтвердите почту"].waitForExistence(timeout: 8))
        shot("email-sheet")
        audit("email-sheet", [
            ("subtitle", text(part: "подтвердите почту")),
            ("send", app.buttons["Подтвердить"].firstMatch)
        ])
        tapButton("Подтвердить")
        XCTAssertTrue(app.textFields["Код из 6 цифр"].waitForExistence(timeout: 8))
        shot("email-sheet-code")
        app.textFields["Код из 6 цифр"].firstMatch.tap()
        sleep(1)
        shot("email-sheet-keyboard")
        audit("email-sheet-keyboard", [
            ("code", app.textFields["Код из 6 цифр"].firstMatch),
            ("confirm", app.buttons["Проверить код"].firstMatch),
            ("resend", app.buttons["Отправить код ещё раз"].firstMatch)
        ])
        app.navigationBars["Подтвердите почту"].buttons.firstMatch.tap()

        openCompatibility()
        shot("compatibility-locked")
        openProfile()
        shot("profile-locked")
        openHistory()
        shot("history-empty")
    }

    private func useWindowDirectory() {
        let width = Int(app.windows.firstMatch.frame.width.rounded())
        let url = URL(fileURLWithPath: "/tmp/aura-ui-audit/\(width)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        directory = url
        print("AUDIT DIR \(url.path) window=\(app.windows.firstMatch.frame)")
    }

    private func shot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let folder = directory ?? URL(fileURLWithPath: "/tmp/aura-ui-audit")
        let url = folder.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: url)
            print("AUDIT SHOT \(url.path)")
        } catch {
            print("AUDIT SHOT FAILED \(name) \(error)")
        }
    }

    private func audit(_ name: String, _ elements: [(String, XCUIElement)]) {
        let window = app.windows.firstMatch.frame
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            print(String(format: "AUDIT %@ | keyboard | y=%.1f h=%.1f", name, keyboard.frame.minY, keyboard.frame.height))
        } else {
            print("AUDIT \(name) | keyboard | MISSING")
        }
        for (label, element) in elements {
            guard element.exists else {
                print("AUDIT \(name) | \(label) | MISSING")
                continue
            }
            let frame = element.frame
            let inside = window.contains(frame)
            print(String(format: "AUDIT %@ | %@ | x=%.1f y=%.1f w=%.1f h=%.1f | inside=%@ hittable=%@",
                         name, label, frame.minX, frame.minY, frame.width, frame.height,
                         inside ? "Y" : "N", element.isHittable ? "Y" : "N"))
        }
    }
}
