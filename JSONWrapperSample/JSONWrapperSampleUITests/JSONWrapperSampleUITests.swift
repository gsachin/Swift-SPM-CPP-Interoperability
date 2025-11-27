//
//  JSONWrapperSampleUITests.swift
//  JSONWrapperSampleUITests
//
//  Created by Work on 11/24/25.
//

import XCTest

final class JSONWrapperSampleUITests: XCTestCase {
    override func setUpWithError() throws {
            continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
