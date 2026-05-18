import XCTest
@testable import SteamControllerKit

final class SteamControllerInputDecoderTests: XCTestCase {

    /// Builds a 45-byte input report from the given field values.
    private func makeReport(sequence: UInt8 = 0,
                            buttons: UInt32 = 0,
                            leftTrigger: Int16 = 0, rightTrigger: Int16 = 0,
                            leftStick: (Int16, Int16) = (0, 0),
                            rightStick: (Int16, Int16) = (0, 0),
                            leftPad: (Int16, Int16) = (0, 0), leftPadPressure: UInt16 = 0,
                            rightPad: (Int16, Int16) = (0, 0), rightPadPressure: UInt16 = 0,
                            timestamp: UInt32 = 0,
                            accelerometer: (Int16, Int16, Int16) = (0, 0, 0),
                            gyroscope: (Int16, Int16, Int16) = (0, 0, 0)) -> [UInt8] {
        func u16(_ value: UInt16) -> [UInt8] { [UInt8(value & 0xFF), UInt8(value >> 8)] }
        func s16(_ value: Int16) -> [UInt8] { u16(UInt16(bitPattern: value)) }
        func u32(_ value: UInt32) -> [UInt8] {
            [UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF),
             UInt8((value >> 16) & 0xFF), UInt8((value >> 24) & 0xFF)]
        }

        var bytes: [UInt8] = [sequence]
        bytes += u32(buttons)
        bytes += s16(leftTrigger) + s16(rightTrigger)
        bytes += s16(leftStick.0) + s16(leftStick.1)
        bytes += s16(rightStick.0) + s16(rightStick.1)
        bytes += s16(leftPad.0) + s16(leftPad.1) + u16(leftPadPressure)
        bytes += s16(rightPad.0) + s16(rightPad.1) + u16(rightPadPressure)
        bytes += u32(timestamp)
        bytes += s16(accelerometer.0) + s16(accelerometer.1) + s16(accelerometer.2)
        bytes += s16(gyroscope.0) + s16(gyroscope.1) + s16(gyroscope.2)
        precondition(bytes.count == SteamControllerInputDecoder.reportLength)
        return bytes
    }

    func testRejectsReportsShorterThanReportLength() {
        XCTAssertNil(SteamControllerInputDecoder.decode([]))
        XCTAssertNil(SteamControllerInputDecoder.decode([UInt8](repeating: 0, count: 44)))
    }

    func testDecodesSequenceAndButtons() {
        let state = SteamControllerInputDecoder.decode(
            makeReport(sequence: 0xAB, buttons: SteamControllerButtons([.a, .steam]).rawValue))
        XCTAssertEqual(state?.sequence, 0xAB)
        XCTAssertEqual(state?.buttons, [.a, .steam])
    }

    func testNormalisesTriggers() {
        let state = SteamControllerInputDecoder.decode(
            makeReport(leftTrigger: .max, rightTrigger: -1))
        XCTAssertEqual(state?.leftTrigger ?? -1, 1.0, accuracy: 0.001)
        XCTAssertEqual(state?.rightTrigger ?? -1, 0.0, accuracy: 0.001)
    }

    func testDecodesSticks() {
        let state = SteamControllerInputDecoder.decode(
            makeReport(leftStick: (1111, -2222), rightStick: (-3333, 4444)))
        XCTAssertEqual(state?.leftStick, SIMD2<Int16>(1111, -2222))
        XCTAssertEqual(state?.rightStick, SIMD2<Int16>(-3333, 4444))
    }

    func testDecodesPadsAndPressures() {
        let state = SteamControllerInputDecoder.decode(
            makeReport(leftPad: (10, 20), leftPadPressure: 5000,
                       rightPad: (-30, -40), rightPadPressure: 60000))
        XCTAssertEqual(state?.leftPad, SIMD2<Int16>(10, 20))
        XCTAssertEqual(state?.leftPadPressure, 5000)
        XCTAssertEqual(state?.rightPad, SIMD2<Int16>(-30, -40))
        XCTAssertEqual(state?.rightPadPressure, 60000)
    }

    func testDecodesMotionSensors() {
        let state = SteamControllerInputDecoder.decode(
            makeReport(accelerometer: (1, -2, 3), gyroscope: (-4, 5, -6)))
        XCTAssertEqual(state?.accelerometer, SIMD3<Int16>(1, -2, 3))
        XCTAssertEqual(state?.gyroscope, SIMD3<Int16>(-4, 5, -6))
    }

    func testDecodesEveryFieldWithoutOverlap() {
        let state = SteamControllerInputDecoder.decode(makeReport(
            sequence: 1,
            buttons: SteamControllerButtons.b.rawValue,
            leftTrigger: 100, rightTrigger: 200,
            leftStick: (300, 400), rightStick: (500, 600),
            leftPad: (700, 800), leftPadPressure: 900,
            rightPad: (1000, 1100), rightPadPressure: 1200,
            timestamp: 0x1234_5678,
            accelerometer: (1300, 1400, 1500), gyroscope: (1600, 1700, 1800)))
        XCTAssertEqual(state?.sequence, 1)
        XCTAssertEqual(state?.buttons, .b)
        XCTAssertEqual(state?.leftStick, SIMD2<Int16>(300, 400))
        XCTAssertEqual(state?.rightStick, SIMD2<Int16>(500, 600))
        XCTAssertEqual(state?.leftPad, SIMD2<Int16>(700, 800))
        XCTAssertEqual(state?.leftPadPressure, 900)
        XCTAssertEqual(state?.rightPad, SIMD2<Int16>(1000, 1100))
        XCTAssertEqual(state?.rightPadPressure, 1200)
        XCTAssertEqual(state?.accelerometer, SIMD3<Int16>(1300, 1400, 1500))
        XCTAssertEqual(state?.gyroscope, SIMD3<Int16>(1600, 1700, 1800))
    }
}
