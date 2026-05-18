import CoreBluetooth
import Foundation

/// The connection lifecycle of a ``SteamControllerBLE`` session.
public enum SteamControllerConnectionState: Equatable, Sendable {
    /// Bluetooth is unavailable. `reason` is a user-facing explanation.
    case bluetoothUnavailable(reason: String)
    /// Not started, or stopped by the caller.
    case idle
    /// Looking for a controller.
    case searching
    /// A controller was found; connecting and preparing it.
    case connecting
    /// Connected and streaming input.
    case ready
    /// Disconnected after being connected. `reason` is `nil` for a clean stop.
    case disconnected(reason: String?)
}

/// Receives connection updates and input from a ``SteamControllerBLE``.
public protocol SteamControllerBLEDelegate: AnyObject {
    /// Called whenever the connection state changes.
    func steamControllerBLE(_ controller: SteamControllerBLE,
                            didChange state: SteamControllerConnectionState)
    /// Called for every input report, on the main thread.
    func steamControllerBLE(_ controller: SteamControllerBLE,
                            didUpdate input: SteamControllerState)
    /// Called with diagnostic messages. Optional.
    func steamControllerBLE(_ controller: SteamControllerBLE, didLog message: String)
}

public extension SteamControllerBLEDelegate {
    func steamControllerBLE(_ controller: SteamControllerBLE, didLog message: String) {}
}

/// Connects to a Steam Controller over Bluetooth LE and streams its full input
/// state, with control over the controller's haptics.
///
/// Create an instance, set a ``delegate``, and call ``start()``. Bluetooth runs
/// on the main thread, so all delegate callbacks arrive on the main thread.
public final class SteamControllerBLE: NSObject {

    /// The delegate that receives connection and input updates.
    public weak var delegate: SteamControllerBLEDelegate?

    /// The current connection state.
    public private(set) var connectionState: SteamControllerConnectionState = .idle {
        didSet {
            guard oldValue != connectionState else { return }
            delegate?.steamControllerBLE(self, didChange: connectionState)
        }
    }

    /// Whether haptic commands can currently be sent.
    public var isHapticsAvailable: Bool { rumbleCharacteristic != nil }

    // MARK: GATT identifiers

    private static let deviceInformationService = CBUUID(string: "180A")
    private static let controllerService = CBUUID(string: "100F6C32-1735-4313-B402-38567131E5F3")
    private static let inputCharacteristicID = CBUUID(string: "100F6C7A-1735-4313-B402-38567131E5F3")
    private static let rumbleCharacteristicID = CBUUID(string: "100F6CB5-1735-4313-B402-38567131E5F3")
    private static let lfoToneCharacteristicID = CBUUID(string: "100F6CB8-1735-4313-B402-38567131E5F3")
    private static let logSweepCharacteristicID = CBUUID(string: "100F6CB9-1735-4313-B402-38567131E5F3")

    // MARK: State

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var inputCharacteristic: CBCharacteristic?
    private var rumbleCharacteristic: CBCharacteristic?
    private var lfoToneCharacteristic: CBCharacteristic?
    private var logSweepCharacteristic: CBCharacteristic?

    private var wantsToRun = false
    private var hasReceivedInput = false

    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: Control

    /// Begins searching for a controller and connects to the first one found.
    ///
    /// Safe to call before Bluetooth is powered on; the search starts
    /// automatically once it becomes available.
    public func start() {
        wantsToRun = true
        if central.state == .poweredOn { beginSearch() }
    }

    /// Disconnects and stops searching.
    public func stop() {
        wantsToRun = false
        central.stopScan()
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        teardown()
        connectionState = .idle
    }

    // MARK: Haptics

    /// Rumbles the controller's two main motors.
    ///
    /// - Parameters:
    ///   - left: left motor strength, `0` (off) to ``SteamControllerHaptics/maxRumbleStrength``.
    ///   - right: right motor strength, `0` (off) to ``SteamControllerHaptics/maxRumbleStrength``.
    ///   - intensity: overall intensity. Defaults to the maximum.
    ///   - gain: per-side gain, `0...127`. Defaults to the maximum.
    public func rumble(left: UInt16, right: UInt16,
                       intensity: UInt16 = SteamControllerHaptics.maxRumbleStrength,
                       gain: Int8 = 127) {
        write(SteamControllerHaptics.rumble(left: left, right: right,
                                            intensity: intensity, gain: gain),
              to: rumbleCharacteristic)
    }

    /// Stops all rumble.
    public func stopRumble() {
        rumble(left: 0, right: 0, intensity: 0)
    }

    /// Plays an oscillator-modulated tone on one side.
    public func lfoTone(side: SteamControllerHaptics.Side, gain: Int8 = 127,
                        frequency: UInt16 = 200, duration: UInt16 = 500,
                        lfoFrequency: UInt16 = 8, lfoDepth: UInt8 = 200) {
        write(SteamControllerHaptics.lfoTone(side: side, gain: gain, frequency: frequency,
                                             duration: duration, lfoFrequency: lfoFrequency,
                                             lfoDepth: lfoDepth),
              to: lfoToneCharacteristic)
    }

    /// Plays a frequency sweep on one side.
    public func logSweep(side: SteamControllerHaptics.Side, gain: Int8 = 127,
                         duration: UInt16 = 800,
                         startFrequency: UInt16 = 80, endFrequency: UInt16 = 300) {
        write(SteamControllerHaptics.logSweep(side: side, gain: gain, duration: duration,
                                              startFrequency: startFrequency,
                                              endFrequency: endFrequency),
              to: logSweepCharacteristic)
    }

    // MARK: Internals

    private func write(_ payload: [UInt8], to characteristic: CBCharacteristic?) {
        guard let peripheral, let characteristic else {
            log("Haptic command ignored: controller not ready.")
            return
        }
        peripheral.writeValue(Data(payload), for: characteristic, type: .withResponse)
    }

    private func beginSearch() {
        connectionState = .searching
        hasReceivedInput = false

        // A controller already paired with the system does not appear in a
        // scan, so check the system's connected peripherals first.
        let connected = central.retrieveConnectedPeripherals(
            withServices: [Self.deviceInformationService])
        if let known = connected.first(where: { ($0.name ?? "").hasPrefix("Steam") }) {
            log("Found controller: \(known.name ?? "Steam Controller").")
            connect(to: known)
            return
        }

        log("Scanning for a controller…")
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    private func connect(to peripheral: CBPeripheral) {
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        connectionState = .connecting
        central.connect(peripheral, options: nil)
    }

    private func teardown() {
        peripheral?.delegate = nil
        peripheral = nil
        inputCharacteristic = nil
        rumbleCharacteristic = nil
        lfoToneCharacteristic = nil
        logSweepCharacteristic = nil
        hasReceivedInput = false
    }

    private func log(_ message: String) {
        delegate?.steamControllerBLE(self, didLog: message)
    }
}

// MARK: - CBCentralManagerDelegate

extension SteamControllerBLE: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if wantsToRun, peripheral == nil { beginSearch() }
        case .poweredOff:
            connectionState = .bluetoothUnavailable(reason: "Bluetooth is turned off.")
        case .unauthorized:
            connectionState = .bluetoothUnavailable(reason: "Bluetooth permission was denied.")
        case .unsupported:
            connectionState = .bluetoothUnavailable(reason: "This device does not support Bluetooth LE.")
        case .resetting:
            connectionState = .bluetoothUnavailable(reason: "Bluetooth is resetting.")
        case .unknown:
            connectionState = .bluetoothUnavailable(reason: "Bluetooth state is unknown.")
        @unknown default:
            connectionState = .bluetoothUnavailable(reason: "Bluetooth is unavailable.")
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String: Any],
                               rssi RSSI: NSNumber) {
        guard self.peripheral == nil else { return }
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? ""
        guard name.hasPrefix("Steam") else { return }
        log("Found controller: \(name).")
        connect(to: peripheral)
    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Self.controllerService])
    }

    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        let reason = error?.localizedDescription ?? "Failed to connect."
        teardown()
        connectionState = .disconnected(reason: reason)
        if wantsToRun { beginSearch() }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        teardown()
        connectionState = .disconnected(reason: error?.localizedDescription)
        if wantsToRun { beginSearch() }
    }
}

// MARK: - CBPeripheralDelegate

extension SteamControllerBLE: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            connectionState = .disconnected(reason: error.localizedDescription)
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.controllerService }) else {
            connectionState = .disconnected(reason: "Controller service not found.")
            return
        }
        peripheral.discoverCharacteristics(nil, for: service)
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case Self.inputCharacteristicID:    inputCharacteristic = characteristic
            case Self.rumbleCharacteristicID:   rumbleCharacteristic = characteristic
            case Self.lfoToneCharacteristicID:  lfoToneCharacteristic = characteristic
            case Self.logSweepCharacteristicID: logSweepCharacteristic = characteristic
            default: break
            }
        }

        guard let inputCharacteristic else {
            connectionState = .disconnected(reason: "Controller input characteristic not found.")
            return
        }
        peripheral.setNotifyValue(true, for: inputCharacteristic)
        log("Connected. Waiting for input…")
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        guard characteristic.uuid == Self.inputCharacteristicID,
              let value = characteristic.value else { return }

        if !hasReceivedInput {
            hasReceivedInput = true
            connectionState = .ready
        }

        if let state = SteamControllerInputDecoder.decode([UInt8](value)) {
            delegate?.steamControllerBLE(self, didUpdate: state)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if let error {
            log("Haptic command failed: \(error.localizedDescription)")
        }
    }
}
