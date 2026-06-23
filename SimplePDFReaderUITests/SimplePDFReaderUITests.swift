import XCTest

final class SimplePDFReaderUITests: XCTestCase {
    func testLibraryLaunches() {
        let app = XCUIApplication()
        app.launch()

        let libraryTab = app.tabBars.buttons["Library"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5))

        let emptyState = app.staticTexts["Import your first PDF"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5) || app.navigationBars["Library"].exists)
    }
}
