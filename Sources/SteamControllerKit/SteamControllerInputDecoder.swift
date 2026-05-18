import Foundation

/// Decodes the controller's Bluetooth LE input report into a ``SteamControllerState``.
///
/// The report is a fixed-layout, little-endian, 45-byte packet:
///
/// | Offset | Field                       | Type      |
/// |--------|-----------------------------|-----------|
/// | 0      | sequence number             | `UInt8`   |
/// | 1      | buttons                     | `UInt32`  |
/// | 5      | left trigger                | `Int16`   |
/// | 7      | right trigger               | `Int16`   |
/// | 9      | left stick X, Y             | `Int16`×2 |
/// | 13     | right stick X, Y            | `Int16`×2 |
/// | 17     | left pad X, Y               | `Int16`×2 |
/// | 21     | left pad pressure           | `UInt16`  |
/// | 23     | right pad X, Y              | `Int16`×2 |
/// | 27     | right pad pressure          | `UInt16`  |
/// | 29     | timestamp                   | `UInt32`  |
/// | 33     | accelerometer X, Y, Z       | `Int16`×3 |
/// | 39     | gyroscope X, Y, Z           | `Int16`×3 |
public enum SteamControllerInputDecoder {

    /// The exact length, in bytes, of a controller input report.
    public static let reportLength = 45

    /// Largest analog trigger value the controller reports, used to normalise
    /// the trigger fields to `0...1`.
    private static let triggerFullScale = Float(Int16.max)

    /// Decodes a raw input report.
    ///
    /// - Parameter data: the bytes of one input report.
    /// - Returns: the decoded state, or `nil` if `data` is shorter than
    ///   ``reportLength``.
    public static func decode(_ data: [UInt8]) -> SteamControllerState? {
        guard data.count >= reportLength else { return nil }

        func u16(_ offset: Int) -> UInt16 {
            UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
        }
        func s16(_ offset: Int) -> Int16 {
            Int16(bitPattern: u16(offset))
        }
        func u32(_ offset: Int) -> UInt32 {
            UInt32(data[offset])
                | (UInt32(data[offset + 1]) << 8)
                | (UInt32(data[offset + 2]) << 16)
                | (UInt32(data[offset + 3]) << 24)
        }

        var state = SteamControllerState()
        state.sequence = data[0]
        state.buttons = SteamControllerButtons(rawValue: u32(1))

        state.leftTrigger = normalisedTrigger(s16(5))
        state.rightTrigger = normalisedTrigger(s16(7))

        state.leftStick = SIMD2(s16(9), s16(11))
        state.rightStick = SIMD2(s16(13), s16(15))

        state.leftPad = SIMD2(s16(17), s16(19))
        state.leftPadPressure = u16(21)
        state.rightPad = SIMD2(s16(23), s16(25))
        state.rightPadPressure = u16(27)

        // Bytes 29...32 hold a device timestamp, which this decoder does not surface.
        state.accelerometer = SIMD3(s16(33), s16(35), s16(37))
        state.gyroscope = SIMD3(s16(39), s16(41), s16(43))

        return state
    }

    private static func normalisedTrigger(_ raw: Int16) -> Float {
        max(0, Float(raw) / triggerFullScale)
    }
}
