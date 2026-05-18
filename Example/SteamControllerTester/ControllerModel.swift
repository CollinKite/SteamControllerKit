import Foundation
import Observation
import SteamControllerKit

/// Observable bridge between ``SteamControllerBLE`` and the SwiftUI views.
@Observable
final class ControllerModel {

    struct LogEntry: Identifiable {
        let id = UUID()
        let time: Date
        let message: String
    }

    private(set) var connectionState: SteamControllerConnectionState = .idle
    private(set) var input = SteamControllerState()
    private(set) var updateCount = 0
    private(set) var log: [LogEntry] = []
    private(set) var isRunning = false

    /// Rumble strength, `0...1`, mapped to the controller's strength range.
    var rumbleStrength: Double = 1.0
    /// Rumble gain, `0...127`.
    var rumbleGain: Double = 127
    /// The side used by the tone and sweep haptic tests.
    var hapticSide: SteamControllerHaptics.Side = .left

    private let controller = SteamControllerBLE()
    private let maxLogEntries = 50

    init() {
        controller.delegate = self
    }

    // MARK: Connection

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        isRunning = true
        controller.start()
    }

    func stop() {
        isRunning = false
        controller.stop()
    }

    // MARK: Haptics

    var canSendHaptics: Bool {
        connectionState == .ready && controller.isHapticsAvailable
    }

    func rumbleLeft()  { pulseRumble(left: true,  right: false) }
    func rumbleRight() { pulseRumble(left: false, right: true) }
    func rumbleBoth()  { pulseRumble(left: true,  right: true) }

    func playTone()  { controller.lfoTone(side: hapticSide) }
    func playSweep() { controller.logSweep(side: hapticSide) }

    private func pulseRumble(left: Bool, right: Bool) {
        let value = UInt16((rumbleStrength
            * Double(SteamControllerHaptics.maxRumbleStrength)).rounded())
        let gain = Int8(rumbleGain.rounded())
        controller.rumble(left: left ? value : 0, right: right ? value : 0,
                          intensity: value, gain: gain)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.controller.stopRumble()
        }
    }

    // MARK: Logging

    private func appendLog(_ message: String) {
        log.insert(LogEntry(time: Date(), message: message), at: 0)
        if log.count > maxLogEntries {
            log.removeLast(log.count - maxLogEntries)
        }
    }
}

// MARK: - SteamControllerBLEDelegate

extension ControllerModel: SteamControllerBLEDelegate {

    func steamControllerBLE(_ controller: SteamControllerBLE,
                            didChange state: SteamControllerConnectionState) {
        connectionState = state
        appendLog("State: \(state.label)")
    }

    func steamControllerBLE(_ controller: SteamControllerBLE,
                            didUpdate input: SteamControllerState) {
        self.input = input
        updateCount += 1
    }

    func steamControllerBLE(_ controller: SteamControllerBLE, didLog message: String) {
        appendLog(message)
    }
}

// MARK: - Display helpers

extension SteamControllerConnectionState {
    var label: String {
        switch self {
        case .bluetoothUnavailable(let reason): return reason
        case .idle: return "Idle"
        case .searching: return "Searching…"
        case .connecting: return "Connecting…"
        case .ready: return "Connected"
        case .disconnected(let reason):
            return reason.map { "Disconnected: \($0)" } ?? "Disconnected"
        }
    }
}
