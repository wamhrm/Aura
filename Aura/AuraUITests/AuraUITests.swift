//
//  AuraUITests.swift
//  AuraUITests
//
//  Created by ddorsat on 01.06.2026.
//

import XCTest

final class AuraUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    @MainActor
    func test_appLaunches_successfully() {
        // Given / When
        app.launch()

        // Then
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func test_tabBar_isVisibleOnLaunch() {
        // Given / When
        app.launch()

        // Then
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
    }
}
