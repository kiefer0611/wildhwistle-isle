import XCTest

/// Drives the real app in the simulator: starting a game, opening every panel, and playing encounters through.
final class SmokeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-reset"] + extra
        app.launch()
        return app
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testStartToMapAndPanels() {
        let app = launch()
        XCTAssertTrue(app.buttons["setOut"].waitForExistence(timeout: 30))
        shot("start")
        app.buttons["pick.burrbit"].tap()
        app.buttons["setOut"].tap()
        XCTAssertTrue(app.buttons["nav.team"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["guideCount"].label, "Guide 1/40")
        shot("map")
        let panels: [(String, String)] = [("nav.team", "Team"), ("nav.guide", "Field guide"), ("nav.notes", "Field notes"), ("nav.map", "Hearth Isle"), ("nav.help", "How to play")]
        for (button, title) in panels {
            app.buttons[button].tap()
            let heading = app.staticTexts["panelTitle"]
            XCTAssertTrue(heading.waitForExistence(timeout: 10), title)
            XCTAssertEqual(heading.label, title)
            shot("panel-" + title)
            app.buttons["panelClose"].tap()
            XCTAssertTrue(app.buttons["nav.team"].waitForExistence(timeout: 10))
        }
        // sailing is locked until a guardian is calmed
        app.buttons["nav.map"].tap()
        XCTAssertTrue(app.staticTexts["panelTitle"].waitForExistence(timeout: 10))
        app.swipeUp()
        let sail = app.buttons["sail.1"]
        if sail.waitForExistence(timeout: 5) { XCTAssertFalse(sail.isEnabled) }
        app.buttons["panelClose"].tap()
    }

    func testTappingTheMapWalks() {
        let app = launch()
        XCTAssertTrue(app.buttons["setOut"].waitForExistence(timeout: 30))
        app.buttons["setOut"].tap()
        XCTAssertTrue(app.buttons["nav.team"].waitForExistence(timeout: 15))
        let map = app.descendants(matching: .any).matching(identifier: "map").firstMatch
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        let before = map.value as? String
        XCTAssertEqual(before, "0 steps taken")
        var moved = false
        let spots: [(CGFloat, CGFloat)] = [(0.75, 0.5), (0.25, 0.5), (0.5, 0.3), (0.5, 0.7), (0.7, 0.35), (0.3, 0.65), (0.6, 0.6), (0.4, 0.4)]
        for (dx, dy) in spots {
            map.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).tap()
            sleep(2)
            if app.buttons["act.leave"].exists { app.buttons["act.leave"].tap() }
            if app.buttons["panelClose"].exists { app.buttons["panelClose"].tap() }
            if map.waitForExistence(timeout: 5), let now = map.value as? String, now != before {
                moved = true
                break
            }
        }
        XCTAssertTrue(moved, "tapping the map never moved the wanderer")
        shot("walked")
    }

    func testWildEncounterPlaysThrough() {
        let app = launch(["-demo", "battle"])
        XCTAssertTrue(app.buttons["act.nudge"].waitForExistence(timeout: 30))
        shot("battle")
        XCTAssertFalse(app.buttons["act.strong"].isEnabled, "strong move is not learned at level 5")
        app.buttons["act.nudge"].tap()
        // whistle once: opens the timing bar, then stop it wherever it is
        let whistle = app.buttons["act.whistle"]
        XCTAssertTrue(whistle.waitForExistence(timeout: 10))
        if whistle.isEnabled {
            whistle.tap()
            XCTAssertTrue(app.buttons["whistleNow"].waitForExistence(timeout: 10))
            shot("whistle")
            app.buttons["whistleNow"].tap()
        }
        // then fight until the encounter is decided either way
        var finished = false
        for _ in 0..<80 {
            if app.buttons["continue"].waitForExistence(timeout: 1) {
                finished = true
                break
            }
            let swap = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'swap.'")).firstMatch
            if swap.exists {
                swap.tap()
                continue
            }
            let hit = app.buttons["act.element"]
            if hit.exists && hit.isEnabled { hit.tap() }
        }
        XCTAssertTrue(finished, "the encounter never reached an end")
        shot("battle-end")
        app.buttons["continue"].tap()
        XCTAssertTrue(app.buttons["nav.team"].waitForExistence(timeout: 15))
        shot("map-after")
    }

    func testGuardianCannotBeWhistledAndLeaveWorks() {
        let app = launch(["-demo", "guardian"])
        XCTAssertTrue(app.buttons["act.leave"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["act.whistle"].isEnabled)
        shot("guardian")
        app.buttons["act.leave"].tap()
        XCTAssertTrue(app.buttons["nav.team"].waitForExistence(timeout: 15))
    }

    func testProgressIsSavedBetweenLaunches() {
        let app = launch()
        XCTAssertTrue(app.buttons["setOut"].waitForExistence(timeout: 30))
        app.buttons["setOut"].tap()
        XCTAssertTrue(app.buttons["nav.team"].waitForExistence(timeout: 15))
        app.terminate()
        let again = XCUIApplication()
        again.launchArguments = ["-uitest"]
        again.launch()
        XCTAssertTrue(again.buttons["nav.team"].waitForExistence(timeout: 30), "the saved game should open straight to the map")
        XCTAssertFalse(again.buttons["setOut"].exists)
    }
}
