import XCTest
@testable import GameCore

final class GameInfoTests: XCTestCase {
    func testName() {
        XCTAssertEqual(GameInfo.name, "Wildwhistle Isle")
    }
}
