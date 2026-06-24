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

    func testSeededPDFOpensAndCapturesScreenshots() {
        let app = XCUIApplication()
        app.launchEnvironment["SIMPLEPDF_SEED_SAMPLE_LIBRARY"] = "1"
        app.launch()

        let documentTitle = app.staticTexts["Quarterly Reading Notes"].firstMatch
        XCTAssertTrue(documentTitle.waitForExistence(timeout: 8))
        attachScreenshot(named: "01-library", app: app)

        documentTitle.tap()
        let searchButton = app.buttons["Search"].firstMatch
        XCTAssertTrue(searchButton.waitForExistence(timeout: 8))
        attachScreenshot(named: "02-reader", app: app)

        app.buttons["Settings"].firstMatch.tap()
        let privacyText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "does not track you")).firstMatch
        XCTAssertTrue(privacyText.waitForExistence(timeout: 8))
        attachScreenshot(named: "03-settings", app: app)
    }

    private func attachScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
