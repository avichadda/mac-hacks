import AppKit
import SwiftUI

struct ForceTouchHackView: View {
    @State private var pressure = 0.0
    @State private var peakPressure = 0.0
    @State private var forceClicks = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ModuleHeader(
                icon: "hand.point.up.braille",
                color: .purple,
                title: "Force Touch Pressure Pad",
                description: "Press and hold inside the pad to turn trackpad pressure into a live control value."
            )

            HStack(spacing: 24) {
                pressurePad

                VStack(spacing: 14) {
                    MetricCard(
                        title: "Pressure",
                        value: pressure.formatted(.number.precision(.fractionLength(2))),
                        systemImage: "gauge.with.dots.needle.33percent",
                        color: .purple
                    )
                    MetricCard(
                        title: "Peak",
                        value: peakPressure.formatted(.number.precision(.fractionLength(2))),
                        systemImage: "arrow.up.right",
                        color: .blue
                    )
                    MetricCard(
                        title: "Force Clicks",
                        value: "\(forceClicks)",
                        systemImage: "hand.tap",
                        color: .orange
                    )
                }
                .frame(width: 220)
            }

            HStack {
                Label(
                    "A Force Touch trackpad is required for continuous pressure and force-click stages.",
                    systemImage: "info.circle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Reset") {
                    pressure = 0
                    peakPressure = 0
                    forceClicks = 0
                }
            }
        }
        .padding(30)
    }

    private var pressurePad: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.12 + pressure * 0.35),
                            Color.blue.opacity(0.08 + pressure * 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.purple.opacity(0.16))
                .frame(
                    width: 90 + pressure * 130,
                    height: 90 + pressure * 130
                )

            VStack(spacing: 10) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.purple)
                Text(pressure > 0 ? "Keep pressing" : "Press here")
                    .font(.title2.bold())
                Text("Pressure \(Int(pressure * 100))%")
                    .foregroundStyle(.secondary)
            }

            PressureCaptureView(
                pressure: $pressure,
                onPeak: { newPeak in
                    peakPressure = max(peakPressure, newPeak)
                },
                onForceClick: {
                    forceClicks += 1
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.purple.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct PressureCaptureView: NSViewRepresentable {
    @Binding var pressure: Double
    let onPeak: (Double) -> Void
    let onForceClick: () -> Void

    func makeNSView(context: Context) -> PressureTrackingView {
        let view = PressureTrackingView()
        view.onPressure = { value in
            pressure = value
            onPeak(value)
        }
        view.onForceClick = onForceClick
        return view
    }

    func updateNSView(_ nsView: PressureTrackingView, context: Context) {
        nsView.onPressure = { value in
            pressure = value
            onPeak(value)
        }
        nsView.onForceClick = onForceClick
    }
}

private final class PressureTrackingView: NSView {
    var onPressure: (Double) -> Void = { _ in }
    var onForceClick: () -> Void = {}
    private var lastStage = 0

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        updatePressure(from: event)
    }

    override func mouseDragged(with event: NSEvent) {
        updatePressure(from: event)
    }

    override func pressureChange(with event: NSEvent) {
        updatePressure(from: event)
        if event.stage >= 2 && lastStage < 2 {
            onForceClick()
        }
        lastStage = event.stage
    }

    override func mouseUp(with event: NSEvent) {
        lastStage = 0
        onPressure(0)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    private func updatePressure(from event: NSEvent) {
        let value = min(max(Double(event.pressure), 0), 1)
        onPressure(value)
    }
}
