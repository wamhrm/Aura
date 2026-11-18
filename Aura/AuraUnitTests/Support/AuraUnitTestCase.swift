//
//  AuraUnitTestCase.swift
//  AuraUnitTests
//
//  Created by wamhrm on 18.11.2026.
//

import XCTest
@testable import Aura

class AuraUnitTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        AppLanguage.localeOverride = Locale(identifier: "ru_RU")
    }

    override func tearDown() {
        AppLanguage.localeOverride = nil
        super.tearDown()
    }
}
