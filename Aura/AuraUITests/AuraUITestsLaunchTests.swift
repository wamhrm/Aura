//
//  AuraUITestsLaunchTests.swift
//  AuraUITests
//
//  Created by wamhrm on 01.06.2026.
//

import XCTest

final class AuraUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        // Given
        let app = XCUIApplication()

        // When
        app.launch()

        // Then
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
