import XCTest

@MainActor
final class PreviewScreenshot: XCTestCase {
    private func launchApp(tab: Int? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["UITEST_SNAPSHOT"]
        if let tab {
            app.launchEnvironment["UITEST_TAB"] = String(tab)
        }
        app.launch()
        return app
    }

    func testCaptureScreenshots() {
        // Launching fresh per tab via UITEST_TAB keeps each shot independent
        // of tab bar layout (it differs between iPhone and iPad).
        let feed = launchApp()
        sleep(3)
        if feed.buttons["Got it"].waitForExistence(timeout: 2) {
            feed.buttons["Got it"].tap()
            sleep(1)
        }
        snapshot("01-feed")
        if feed.buttons["Technology"].isHittable {
            feed.buttons["Technology"].tap()
            sleep(1)
        }
        snapshot("02-feed-filtered")
        feed.terminate()

        let create = launchApp(tab: 1)
        sleep(3)
        snapshot("03-create")
        create.terminate()

        let profile = launchApp(tab: 2)
        sleep(3)
        snapshot("04-profile")
        profile.terminate()

        let ideas = launchApp(tab: 3)
        sleep(3)
        ideas.swipeUp()
        ideas.swipeUp()
        ideas.swipeUp()
        sleep(1)
        snapshot("05-ideas")
        ideas.terminate()
    }
}
