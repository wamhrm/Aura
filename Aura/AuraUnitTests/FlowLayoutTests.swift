//
//  FlowLayoutTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 18.11.2026.
//

import SwiftUI
import XCTest
@testable import Aura

@MainActor
final class FlowLayoutTests: AuraUnitTestCase {
    func test_unspecifiedWidth_fitsTheChildrenOnOneRow() {
        let host = UIHostingController(rootView: flow.fixedSize())

        let size = host.sizeThatFits(in: CGSize(width: 100, height: 200))

        XCTAssertEqual(size, CGSize(width: 160, height: 20))
    }

    func test_firstChildWiderThanTheProposal_doesNotAddAnEmptyRow() {
        let host = UIHostingController(rootView: flow)

        let size = host.sizeThatFits(in: CGSize(width: 100, height: 200))

        XCTAssertEqual(size, CGSize(width: 100, height: 42))
    }

    private var flow: some View {
        FlowLayout {
            Color.red.frame(width: 120, height: 20)
            Color.blue.frame(width: 32, height: 14)
        }
    }
}
