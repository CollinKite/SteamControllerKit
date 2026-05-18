# SteamControllerKit

A Swift package for using the **Steam Controller** as a full gamepad over
Bluetooth LE on iOS, iPadOS, and tvOS.

It connects to the controller, streams every input — both thumbsticks, both
trackpads with pressure, analog triggers, all 30 buttons and touch sensors, and
the motion sensors — and drives the controller's haptics.

## Features

- Automatic discovery and connection over Bluetooth LE
- Full input decoding into a single `SteamControllerState` value:
  - Left and right thumbsticks
  - Left and right trackpads, with pressure
  - Analog triggers, normalised to `0...1`
  - 30 named buttons and capacitive touch sensors
  - Accelerometer and gyroscope
- Haptics: rumble, oscillator-modulated tones, and frequency sweeps
- Pure Swift, no third-party dependencies
- Builds for iOS, iPadOS, and tvOS

## Requirements

- iOS 26, iPadOS 26, or tvOS 26
- A physical device — the Simulator has no Bluetooth
- An app that declares `NSBluetoothAlwaysUsageDescription` in its Info.plist

## Installation

Add the package in Xcode via **File ▸ Add Package Dependencies…**, or add it to
your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CollinKite/SteamControllerKit.git", from: "1.0.0"),
]
```

## Usage

Create a `SteamControllerBLE`, set a delegate, and call `start()`. All delegate
callbacks arrive on the main thread.

```swift
import SteamControllerKit

final class GameInput: SteamControllerBLEDelegate {
    private let controller = SteamControllerBLE()

    init() {
        controller.delegate = self
        controller.start()
    }

    func steamControllerBLE(_ controller: SteamControllerBLE,
                            didChange state: SteamControllerConnectionState) {
        print("Connection state: \(state)")
    }

    func steamControllerBLE(_ controller: SteamControllerBLE,
                            didUpdate input: SteamControllerState) {
        if input.buttons.contains(.a) {
            jump()
        }
        move(x: input.leftStick.x, y: input.leftStick.y)
        aim(x: input.rightStick.x, y: input.rightStick.y)
    }
}
```

### Haptics

```swift
// Rumble the left motor at full strength.
controller.rumble(left: SteamControllerHaptics.maxRumbleStrength, right: 0)
controller.stopRumble()

// Play a tone and a frequency sweep.
controller.lfoTone(side: .left)
controller.logSweep(side: .right)
```

## Example app

`Example/` contains **SteamControllerTester**, a SwiftUI app for iOS, iPadOS,
and tvOS that connects to a controller and shows every input live, with controls
to test the haptics.

The project is generated with [XcodeGen](https://github.com/yonsky/XcodeGen):

```sh
cd Example
xcodegen generate
open SteamControllerTester.xcodeproj
```

Select your Apple Developer team in **Signing & Capabilities**, then run it on a
physical device.

## How it was built

The Steam Controller's Bluetooth LE protocol is implemented in
[SDL](https://github.com/libsdl-org/SDL)'s open-source code, where its input
report and haptic packet layouts and GATT identifiers can be found. Inspecting
the Steam Link app for iOS confirmed that it relies on SDL for controller
input, which is what pointed to SDL's Steam Controller support as the reference
for those details.

The remaining specifics for the 2026 controller — the 32-bit button mapping and
the haptic calibration — were reverse-engineered independently by capturing and
analyzing live Bluetooth traffic from real hardware.

SDL is distributed under the zlib license and includes contributions from Valve
Corporation. All code in this repository is original.

## Contributing

Contributions are welcome — issues and pull requests both. Useful areas include
support for the original (2015) Steam Controller, additional haptic effects, and
testing across firmware revisions.

## Disclaimer

SteamControllerKit is an independent project and is not affiliated with,
endorsed by, or sponsored by Valve Corporation. "Steam" and "Steam Controller"
are trademarks of Valve Corporation.

## License

MIT — see [LICENSE](LICENSE).
