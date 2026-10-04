import XCTest

// Drives a slow tour of the app while `simctl io recordVideo` films it.
// Used for the landing page promo, not a correctness test.
@MainActor
final class PromoTour: XCTestCase {
    func testTour() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT"]
        app.launch()
        sleep(3)
        if app.buttons["Got it"].waitForExistence(timeout: 4) {
            sleep(2)
            app.buttons["Got it"].tap()
        }
        sleep(2)
        for chip in ["Technology", "Design", "All"] where app.buttons[chip].exists {
            app.buttons[chip].tap()
            sleep(1)
        }
        app.swipeUp(velocity: .slow)
        sleep(1)
        app.swipeDown(velocity: .slow)
        sleep(1)
        let card = app.cells.element(boundBy: 1)
        if card.exists {
            card.tap()
            sleep(3)
            app.swipeUp(velocity: .slow)
            sleep(2)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
        for tab in ["Ideas", "Create", "Profile", "Feed"] {
            app.tabBars.buttons[tab].tap()
            sleep(2)
        }
    }
}
