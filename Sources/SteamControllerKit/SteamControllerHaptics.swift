import Foundation

/// Builders for the controller's haptic command payloads.
///
/// Each function returns the raw bytes of one command. ``SteamControllerBLE``
/// uses these to drive the controller's haptics; they are exposed publicly so
/// payloads can be inspected or sent over a custom transport.
public enum SteamControllerHaptics {

    /// The side a single-sided haptic effect targets.
    public enum Side: UInt8, Sendable, CaseIterable {
        case left = 0
        case right = 1
    }

    /// The strongest usable value for the 16-bit rumble strength fields.
    ///
    /// The fields are interpreted as signed, so strength tracks magnitude and
    /// peaks here; larger raw values wrap and weaken the effect.
    public static let maxRumbleStrength: UInt16 = 0x7FFF

    private static func littleEndian(_ value: UInt16) -> [UInt8] {
        [UInt8(value & 0xFF), UInt8(value >> 8)]
    }

    /// Builds a rumble command driving the two main motors.
    ///
    /// - Parameters:
    ///   - left: left motor strength, `0` (off) to ``maxRumbleStrength``.
    ///   - right: right motor strength, `0` (off) to ``maxRumbleStrength``.
    ///   - intensity: overall intensity, `0` to ``maxRumbleStrength``.
    ///   - gain: per-side gain, `0...127`.
    public static func rumble(left: UInt16, right: UInt16,
                              intensity: UInt16, gain: Int8) -> [UInt8] {
        let gainByte = UInt8(bitPattern: gain)
        return [0]
            + littleEndian(intensity)
            + littleEndian(left) + [gainByte]
            + littleEndian(right) + [gainByte]
    }

    /// Builds a tone command modulated by a low-frequency oscillator, which
    /// gives the effect a pulsing character.
    ///
    /// - Parameters:
    ///   - side: which side to play the tone on.
    ///   - gain: gain, `0...127`.
    ///   - frequency: tone frequency, in hertz.
    ///   - duration: effect duration, in milliseconds.
    ///   - lfoFrequency: modulation rate, in hertz.
    ///   - lfoDepth: modulation depth, `0...255`.
    public static func lfoTone(side: Side, gain: Int8, frequency: UInt16,
                               duration: UInt16, lfoFrequency: UInt16,
                               lfoDepth: UInt8) -> [UInt8] {
        [side.rawValue, UInt8(bitPattern: gain)]
            + littleEndian(frequency)
            + littleEndian(duration)
            + littleEndian(lfoFrequency)
            + [lfoDepth]
    }

    /// Builds a command that sweeps frequency from `startFrequency` to
    /// `endFrequency` over `duration`, producing a rising or falling effect.
    ///
    /// - Parameters:
    ///   - side: which side to play the sweep on.
    ///   - gain: gain, `0...127`.
    ///   - duration: sweep duration, in milliseconds.
    ///   - startFrequency: starting frequency, in hertz.
    ///   - endFrequency: ending frequency, in hertz.
    public static func logSweep(side: Side, gain: Int8, duration: UInt16,
                                startFrequency: UInt16, endFrequency: UInt16) -> [UInt8] {
        [side.rawValue, UInt8(bitPattern: gain)]
            + littleEndian(duration)
            + littleEndian(startFrequency)
            + littleEndian(endFrequency)
    }
}
