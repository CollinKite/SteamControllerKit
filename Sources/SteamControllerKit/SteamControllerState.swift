import Foundation

/// A decoded snapshot of every input the controller reports in a single update.
///
/// Stick and trackpad axes are signed 16-bit values centred near zero; trigger
/// values are normalised to `0...1`. Accelerometer and gyroscope values are the
/// raw signed 16-bit sensor readings.
public struct SteamControllerState: Equatable, Sendable {

    /// Per-packet sequence counter, incremented by the controller and wrapping
    /// at 256. Useful for detecting dropped updates.
    public var sequence: UInt8 = 0

    /// Pressed buttons and active touch sensors.
    public var buttons = SteamControllerButtons()

    /// Left thumbstick position, each axis roughly `-32768...32767`.
    public var leftStick = SIMD2<Int16>(0, 0)

    /// Right thumbstick position, each axis roughly `-32768...32767`.
    public var rightStick = SIMD2<Int16>(0, 0)

    /// Left trackpad position. Reads `(0, 0)` while the pad is not touched.
    public var leftPad = SIMD2<Int16>(0, 0)

    /// Right trackpad position. Reads `(0, 0)` while the pad is not touched.
    public var rightPad = SIMD2<Int16>(0, 0)

    /// Left trackpad pressure.
    public var leftPadPressure: UInt16 = 0

    /// Right trackpad pressure.
    public var rightPadPressure: UInt16 = 0

    /// Left analog trigger, normalised to `0...1`.
    public var leftTrigger: Float = 0

    /// Right analog trigger, normalised to `0...1`.
    public var rightTrigger: Float = 0

    /// Accelerometer reading, raw signed 16-bit per axis.
    public var accelerometer = SIMD3<Int16>(0, 0, 0)

    /// Gyroscope reading, raw signed 16-bit per axis.
    public var gyroscope = SIMD3<Int16>(0, 0, 0)

    public init() {}
}
