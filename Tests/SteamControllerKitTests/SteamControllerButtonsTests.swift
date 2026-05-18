import XCTest
@testable import SteamControllerKit

final class SteamControllerButtonsTests: XCTestCase {

    func testBitPositions() {
        XCTAssertEqual(SteamControllerButtons.a.rawValue, 1 << 0)
        XCTAssertEqual(SteamControllerButtons.y.rawValue, 1 << 3)
        XCTAssertEqual(SteamControllerButtons.rightBumper.rawValue, 1 << 9)
        XCTAssertEqual(SteamControllerButtons.dpadUp.rawValue, 1 << 13)
        XCTAssertEqual(SteamControllerButtons.steam.rawValue, 1 << 16)
        XCTAssertEqual(SteamControllerButtons.rightTrigger.rawValue, 1 << 23)
        XCTAssertEqual(SteamControllerButtons.leftTrigger.rawValue, 1 << 27)
        XCTAssertEqual(SteamControllerButtons.leftGrip.rawValue, 1 << 29)
    }

    func testSetMembership() {
        let pressed = SteamControllerButtons(rawValue: SteamControllerButtons([.a, .steam]).rawValue)
        XCTAssertTrue(pressed.contains(.a))
        XCTAssertTrue(pressed.contains(.steam))
        XCTAssertFalse(pressed.contains(.b))
    }

    func testAllLabeledCoversEveryDefinedButton() {
        XCTAssertEqual(SteamControllerButtons.allLabeled.count, 30)
        let union = SteamControllerButtons.allLabeled
            .reduce(into: SteamControllerButtons()) { $0.insert($1.button) }
        XCTAssertEqual(union.rawValue.nonzeroBitCount, 30)
    }
}
