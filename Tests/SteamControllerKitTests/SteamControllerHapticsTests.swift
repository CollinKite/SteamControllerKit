import XCTest
@testable import SteamControllerKit

final class SteamControllerHapticsTests: XCTestCase {

    func testRumblePayload() {
        let payload = SteamControllerHaptics.rumble(
            left: 0x1234, right: 0x5678, intensity: 0x7FFF, gain: 127)
        XCTAssertEqual(payload, [0x00, 0xFF, 0x7F, 0x34, 0x12, 127, 0x78, 0x56, 127])
    }

    func testRumbleEncodesNegativeGainAsTwosComplement() {
        let payload = SteamControllerHaptics.rumble(left: 0, right: 0, intensity: 0, gain: -1)
        XCTAssertEqual(payload[5], 0xFF)
        XCTAssertEqual(payload[8], 0xFF)
    }

    func testLFOTonePayload() {
        let payload = SteamControllerHaptics.lfoTone(
            side: .left, gain: 127, frequency: 200,
            duration: 500, lfoFrequency: 8, lfoDepth: 200)
        XCTAssertEqual(payload.count, 9)
        XCTAssertEqual(payload[0], 0)                  // side: left
        XCTAssertEqual(payload[1], 127)                // gain
        XCTAssertEqual([payload[2], payload[3]], [200, 0])     // frequency
        XCTAssertEqual([payload[4], payload[5]], [0xF4, 0x01]) // duration: 500
        XCTAssertEqual([payload[6], payload[7]], [8, 0])       // lfo frequency
        XCTAssertEqual(payload[8], 200)                // lfo depth
    }

    func testLogSweepPayload() {
        let payload = SteamControllerHaptics.logSweep(
            side: .right, gain: 100, duration: 800,
            startFrequency: 80, endFrequency: 300)
        XCTAssertEqual(payload.count, 8)
        XCTAssertEqual(payload[0], 1)                  // side: right
        XCTAssertEqual(payload[1], 100)                // gain
        XCTAssertEqual([payload[2], payload[3]], [0x20, 0x03]) // duration: 800
        XCTAssertEqual([payload[4], payload[5]], [80, 0])      // start frequency
        XCTAssertEqual([payload[6], payload[7]], [0x2C, 0x01]) // end frequency: 300
    }
}
