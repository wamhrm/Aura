//
//  AuraUITests.swift
//  AuraUITests
//
//  Created by ddorsat on 01.06.2026.
//

import XCTest

final class AuraUITests: XCTestCase {
    @MainActor private lazy var app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_appLaunches_successfully() {
        // Given / When
        app.launch()

        // Then
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func test_firstScreen_isVisibleOnLaunch() {
        // Given
        let firstScreen = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR elementType == %d",
                                  "У меня уже есть аккаунт",
                                  XCUIElement.ElementType.tabBar.rawValue))
            .firstMatch

        // When
        app.launch()

        // Then
        XCTAssertTrue(firstScreen.waitForExistence(timeout: 15))
    }
}
