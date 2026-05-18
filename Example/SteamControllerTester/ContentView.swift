import SwiftUI
import SteamControllerKit

struct ContentView: View {
    @Bindable var model: ControllerModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusCard
                if case .bluetoothUnavailable = model.connectionState {
                    EmptyView()
                } else {
                    buttonsCard
                    axesCard
                    rumbleCard
                    hapticsCard
                    motionCard
                }
                logCard
            }
            .padding()
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Status

    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Circle().fill(statusColor).frame(width: 14, height: 14)
                Text(model.connectionState.label).font(.headline)
                Spacer()
                Text("\(model.updateCount) updates")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Button(model.isRunning ? "Stop" : "Start") { model.toggle() }
                .buttonStyle(.borderedProminent)
                .tint(model.isRunning ? .red : .green)
        }
        .cardStyle()
    }

    private var statusColor: Color {
        switch model.connectionState {
        case .ready: return .green
        case .bluetoothUnavailable, .disconnected: return .red
        case .idle: return .gray
        case .searching, .connecting: return .orange
        }
    }

    // MARK: Buttons

    private var buttonsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("Buttons")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], spacing: 6) {
                ForEach(Array(SteamControllerButtons.allLabeled.enumerated()), id: \.offset) { _, entry in
                    let isOn = model.input.buttons.contains(entry.button)
                    Text(entry.label)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isOn ? Color.green : Color.gray.opacity(0.18),
                                    in: RoundedRectangle(cornerRadius: 7))
                        .foregroundStyle(isOn ? Color.white : Color.secondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Sticks, pads, triggers

    private var axesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Sticks & Pads")
            HStack(spacing: 16) {
                StickPadView(title: "L Stick", value: model.input.leftStick, active: false)
                StickPadView(title: "R Stick", value: model.input.rightStick, active: false)
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 16) {
                StickPadView(title: "L Pad  p:\(model.input.leftPadPressure)",
                             value: model.input.leftPad,
                             active: model.input.leftPadPressure > 0)
                StickPadView(title: "R Pad  p:\(model.input.rightPadPressure)",
                             value: model.input.rightPad,
                             active: model.input.rightPadPressure > 0)
            }
            .frame(maxWidth: .infinity)

            cardTitle("Triggers")
            TriggerBar(label: "LT", value: model.input.leftTrigger)
            TriggerBar(label: "RT", value: model.input.rightTrigger)
        }
        .cardStyle()
    }

    // MARK: Rumble

    private var rumbleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("Rumble")
            HStack(spacing: 10) {
                actionButton("Left", action: model.rumbleLeft)
                actionButton("Both", action: model.rumbleBoth)
                actionButton("Right", action: model.rumbleRight)
            }
            .disabled(!model.canSendHaptics)
            #if os(iOS)
            slider("Strength", value: $model.rumbleStrength, range: 0...1,
                   display: "\(Int((model.rumbleStrength * 100).rounded()))%")
            slider("Gain", value: $model.rumbleGain, range: 0...127,
                   display: "\(Int(model.rumbleGain.rounded()))")
            #endif
        }
        .cardStyle()
    }

    // MARK: Haptics

    private var hapticsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("Haptics")
            HStack(spacing: 8) {
                ForEach(SteamControllerHaptics.Side.allCases, id: \.self) { side in
                    let selected = model.hapticSide == side
                    Button(side == .left ? "Left side" : "Right side") {
                        model.hapticSide = side
                    }
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(selected ? Color.accentColor : Color.gray.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 7))
                    .foregroundStyle(selected ? Color.white : Color.secondary)
                }
            }
            HStack(spacing: 10) {
                actionButton("Tone", action: model.playTone)
                actionButton("Sweep", action: model.playSweep)
            }
            .disabled(!model.canSendHaptics)
        }
        .cardStyle()
    }

    // MARK: Motion

    private var motionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardTitle("Motion")
            infoRow("Sequence", "\(model.input.sequence)")
            let accel = model.input.accelerometer
            infoRow("Accelerometer", "\(accel.x), \(accel.y), \(accel.z)")
            let gyro = model.input.gyroscope
            infoRow("Gyroscope", "\(gyro.x), \(gyro.y), \(gyro.z)")
        }
        .cardStyle()
    }

    // MARK: Log

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            cardTitle("Activity")
            ForEach(model.log.prefix(8)) { entry in
                Text(entry.message)
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    // MARK: Building blocks

    private func cardTitle(_ text: String) -> some View {
        Text(text).font(.subheadline.weight(.semibold))
    }

    private func infoRow(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.monospacedDigit())
        }
    }

    private func actionButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
    }

    #if os(iOS)
    private func slider(_ label: String, value: Binding<Double>,
                        range: ClosedRange<Double>, display: String) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.caption).frame(width: 64, alignment: .leading)
            Slider(value: value, in: range)
            Text(display).font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
        }
    }
    #endif
}

// MARK: - Stick / pad visualiser

struct StickPadView: View {
    let title: String
    let value: SIMD2<Int16>
    let active: Bool

    private let size: CGFloat = 110

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                Rectangle().fill(Color.gray.opacity(0.25)).frame(width: size, height: 1)
                Rectangle().fill(Color.gray.opacity(0.25)).frame(width: 1, height: size)
                Circle()
                    .fill(active ? Color.green : Color.blue)
                    .frame(width: 16, height: 16)
                    .offset(x: offset(value.x), y: -offset(value.y))
            }
            .frame(width: size, height: size)
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text("\(value.x), \(value.y)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    private func offset(_ raw: Int16) -> CGFloat {
        let normalised = max(-1, min(1, CGFloat(raw) / 32768))
        return normalised * (size / 2 - 8)
    }
}

// MARK: - Trigger bar

struct TriggerBar: View {
    let label: String
    let value: Float

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption.monospaced())
                .frame(width: 28, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 5).fill(Color.green)
                        .frame(width: geometry.size.width * CGFloat(max(0, min(1, value))))
                }
            }
            .frame(height: 14)
            Text(String(format: "%3.0f%%", value * 100))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

// MARK: - Card styling

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
