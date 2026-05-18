import Foundation

/// The digital buttons and capacitive sensors reported by the controller.
///
/// Backed by the 32-bit button field of the input report. The grips and the
/// stick/pad "touch" members are capacitive sensors — they report active while
/// the relevant surface is touched, not only when clicked.
public struct SteamControllerButtons: OptionSet, Sendable, Hashable {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let a               = SteamControllerButtons(rawValue: 1 << 0)
    public static let b               = SteamControllerButtons(rawValue: 1 << 1)
    public static let x               = SteamControllerButtons(rawValue: 1 << 2)
    public static let y               = SteamControllerButtons(rawValue: 1 << 3)
    /// The quick-access ("…") menu button.
    public static let quickAccess     = SteamControllerButtons(rawValue: 1 << 4)
    /// Right stick click (R3).
    public static let rightStickClick = SteamControllerButtons(rawValue: 1 << 5)
    public static let start           = SteamControllerButtons(rawValue: 1 << 6)
    /// Upper right back paddle.
    public static let r4              = SteamControllerButtons(rawValue: 1 << 7)
    /// Lower right back paddle.
    public static let r5              = SteamControllerButtons(rawValue: 1 << 8)
    /// Right bumper (R1).
    public static let rightBumper     = SteamControllerButtons(rawValue: 1 << 9)
    public static let dpadDown        = SteamControllerButtons(rawValue: 1 << 10)
    public static let dpadRight       = SteamControllerButtons(rawValue: 1 << 11)
    public static let dpadLeft        = SteamControllerButtons(rawValue: 1 << 12)
    public static let dpadUp          = SteamControllerButtons(rawValue: 1 << 13)
    public static let select          = SteamControllerButtons(rawValue: 1 << 14)
    /// Left stick click (L3).
    public static let leftStickClick  = SteamControllerButtons(rawValue: 1 << 15)
    /// The Steam button.
    public static let steam           = SteamControllerButtons(rawValue: 1 << 16)
    /// Upper left back paddle.
    public static let l4              = SteamControllerButtons(rawValue: 1 << 17)
    /// Lower left back paddle.
    public static let l5              = SteamControllerButtons(rawValue: 1 << 18)
    /// Left bumper (L1).
    public static let leftBumper      = SteamControllerButtons(rawValue: 1 << 19)
    /// Right stick touch sensor (capacitive).
    public static let rightStickTouch = SteamControllerButtons(rawValue: 1 << 20)
    /// Right trackpad touch sensor (capacitive).
    public static let rightPadTouch   = SteamControllerButtons(rawValue: 1 << 21)
    /// Right trackpad click.
    public static let rightPadClick   = SteamControllerButtons(rawValue: 1 << 22)
    /// Right trigger fully pressed (R2). The analog value is reported separately.
    public static let rightTrigger    = SteamControllerButtons(rawValue: 1 << 23)
    /// Left stick touch sensor (capacitive).
    public static let leftStickTouch  = SteamControllerButtons(rawValue: 1 << 24)
    /// Left trackpad touch sensor (capacitive).
    public static let leftPadTouch    = SteamControllerButtons(rawValue: 1 << 25)
    /// Left trackpad click.
    public static let leftPadClick    = SteamControllerButtons(rawValue: 1 << 26)
    /// Left trigger fully pressed (L2). The analog value is reported separately.
    public static let leftTrigger     = SteamControllerButtons(rawValue: 1 << 27)
    /// Right grip touch sensor (capacitive).
    public static let rightGrip       = SteamControllerButtons(rawValue: 1 << 28)
    /// Left grip touch sensor (capacitive).
    public static let leftGrip        = SteamControllerButtons(rawValue: 1 << 29)

    /// Every button paired with a short human-readable label, in a stable
    /// order suitable for display.
    public static let allLabeled: [(button: SteamControllerButtons, label: String)] = [
        (.a, "A"), (.b, "B"), (.x, "X"), (.y, "Y"),
        (.dpadUp, "D-Up"), (.dpadDown, "D-Down"), (.dpadLeft, "D-Left"), (.dpadRight, "D-Right"),
        (.leftBumper, "L1"), (.rightBumper, "R1"),
        (.leftTrigger, "L2"), (.rightTrigger, "R2"),
        (.leftStickClick, "L3"), (.rightStickClick, "R3"),
        (.l4, "L4"), (.r4, "R4"), (.l5, "L5"), (.r5, "R5"),
        (.steam, "Steam"), (.start, "Start"), (.select, "Select"), (.quickAccess, "… Menu"),
        (.leftGrip, "L Grip"), (.rightGrip, "R Grip"),
        (.leftStickTouch, "L Stick Touch"), (.rightStickTouch, "R Stick Touch"),
        (.leftPadTouch, "L Pad Touch"), (.leftPadClick, "L Pad Click"),
        (.rightPadTouch, "R Pad Touch"), (.rightPadClick, "R Pad Click"),
    ]
}
