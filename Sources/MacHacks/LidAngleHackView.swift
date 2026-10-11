import IOKit
import IOKit.hid
import SwiftUI

struct LidAngleHackView: View {
    @State private var angle: Double?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ModuleHeader(
                    icon: "laptopcomputer",
                    color: .blue,
                    title: "Live Lid Angle",
                    description: "Move the display to use your MacBook lid as a physical input."
                )

                if let angle {
                    HStack(spacing: 28) {
                        LidGauge(angle: angle)

                        VStack(spacing: 14) {
                            MetricCard(
                                title: "Lid Angle",
                                value: "\(Int(angle.rounded()))°",
                                systemImage: "angle",
                                color: .blue
                            )
                            MetricCard(
                                title: "Position",
                                value: positionDescription(angle),
                                systemImage: "laptopcomputer",
                                color: .purple
                            )
                        }
                        .frame(width: 240)
                    }
                } else if let errorMessage {
                    ModuleUnavailable(
                        title: "Lid sensor unavailable",
                        description: errorMessage
                    )
                } else {
                    ProgressView("Connecting to the lid sensor...")
                        .frame(maxWidth: .infinity, minHeight: 260)
                }

                Label(
                    "This uses an undocumented Apple HID sensor and may not work on every MacBook or macOS release.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(30)
        }
        .task {
            await monitorAngle()
        }
    }

    @MainActor
    private func monitorAngle() async {
        do {
            let sensor = try LidAngleSensor()
            try sensor.open()

            while !Task.isCancelled {
                angle = try sensor.readAngle()
                errorMessage = nil
                try await Task.sleep(for: .milliseconds(100))
            }
        } catch is CancellationError {
            return
        } catch {
            angle = nil
            errorMessage = error.localizedDescription
        }
    }

    private func positionDescription(_ angle: Double) -> String {
        switch angle {
        case ..<20: "Nearly Closed"
        case ..<80: "Partly Open"
        case ..<120: "Comfortable"
        case ..<160: "Wide Open"
        default: "Fully Open"
        }
    }
}

private struct LidGauge: View {
    let angle: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(.blue.opacity(0.08))

            VStack(spacing: 28) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.secondary)
                        .frame(width: 190, height: 10)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.gradient)
                        .frame(width: 150, height: 9)
                        .rotationEffect(.degrees(-min(max(angle, 0), 180)), anchor: .leading)
                        .offset(x: 75)
                }
                .frame(width: 220, height: 180, alignment: .bottom)

                Text("Move the lid gently")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 330)
    }
}

private final class LidAngleSensor {
    private static let noOptions = IOOptionBits(kIOHIDOptionsTypeNone)
    private static let reportID: CFIndex = 1
    private let device: IOHIDDevice
    private var isOpen = false
    private var report = [UInt8](repeating: 0, count: 8)

    init() throws {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, Self.noOptions)
        let match: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x05AC,
            kIOHIDProductIDKey as String: 0x8104,
            kIOHIDDeviceUsagePageKey as String: 0x20,
            kIOHIDDeviceUsageKey as String: 0x8A
        ]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        IOHIDManagerOpen(manager, Self.noOptions)
        defer { IOHIDManagerClose(manager, Self.noOptions) }

        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
              let device = devices.first else {
            throw LidSensorError.unavailable
        }
        self.device = device
    }

    deinit {
        if isOpen {
            IOHIDDeviceClose(device, Self.noOptions)
        }
    }

    func open() throws {
        let result = IOHIDDeviceOpen(device, Self.noOptions)
        guard result == kIOReturnSuccess else {
            throw LidSensorError.openFailed(result)
        }
        isOpen = true
    }

    func readAngle() throws -> Double {
        var length = CFIndex(report.count)
        let result = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeFeature,
            Self.reportID,
            &report,
            &length
        )
        guard result == kIOReturnSuccess else {
            throw LidSensorError.readFailed(result)
        }
        guard length >= 3 else {
            throw LidSensorError.invalidReport
        }
        return Double(UInt16(report[1]) | (UInt16(report[2]) << 8))
    }
}

private enum LidSensorError: LocalizedError {
    case unavailable
    case openFailed(IOReturn)
    case readFailed(IOReturn)
    case invalidReport

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "This Mac does not expose a compatible lid-angle sensor."
        case .openFailed(let code):
            "The lid sensor could not be opened (IOKit error \(code))."
        case .readFailed(let code):
            "The lid angle could not be read (IOKit error \(code))."
        case .invalidReport:
            "The lid sensor returned an unsupported report."
        }
    }
}
