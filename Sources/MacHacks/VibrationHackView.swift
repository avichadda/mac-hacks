import IOKit
import IOKit.hid
import SwiftUI

struct VibrationHackView: View {
    @State private var sensor = VibrationSensor()
    @State private var sensitivity = 0.12

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { _ in
            let snapshot = sensor.snapshot

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ModuleHeader(
                        icon: "waveform.path",
                        color: .pink,
                        title: "Vibration & Knock Detector",
                        description: "Tap the table or MacBook gently and watch its built-in accelerometer react."
                    )

                    if let error = snapshot.error {
                        ModuleUnavailable(
                            title: "Motion sensor unavailable",
                            description: error
                        )
                    } else if !snapshot.isConnected {
                        ProgressView("Connecting to the motion sensor...")
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        vibrationDashboard(snapshot)
                    }

                    Label(
                        "Uses an undocumented Apple SPU accelerometer. Support varies by Mac model; avoid striking the hardware.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(30)
            }
        }
        .onAppear {
            sensor.threshold = sensitivity
            sensor.start()
        }
        .onDisappear {
            sensor.stop()
        }
        .onChange(of: sensitivity) { newValue in
            sensor.threshold = newValue
        }
    }

    private func vibrationDashboard(_ snapshot: VibrationSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.pink.opacity(0.08))

                Circle()
                    .fill(.pink.opacity(0.15))
                    .frame(
                        width: 70 + min(snapshot.intensity * 500, 230),
                        height: 70 + min(snapshot.intensity * 500, 230)
                    )
                    .animation(.easeOut(duration: 0.08), value: snapshot.intensity)

                VStack(spacing: 8) {
                    Image(systemName: snapshot.intensity >= sensitivity ? "waveform.path.ecg" : "waveform.path")
                        .font(.system(size: 44))
                        .foregroundStyle(.pink)
                    Text(snapshot.intensity >= sensitivity ? "Vibration detected" : "Listening")
                        .font(.title2.bold())
                    Text(snapshot.intensity.formatted(.number.precision(.fractionLength(3))) + " g")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 230)

            HStack(spacing: 14) {
                MetricCard(
                    title: "Current",
                    value: snapshot.intensity.formatted(.number.precision(.fractionLength(3))) + " g",
                    systemImage: "waveform",
                    color: .pink
                )
                MetricCard(
                    title: "Peak",
                    value: snapshot.peak.formatted(.number.precision(.fractionLength(3))) + " g",
                    systemImage: "arrow.up.right",
                    color: .purple
                )
                MetricCard(
                    title: "Knocks",
                    value: "\(snapshot.knockCount)",
                    systemImage: "hand.tap",
                    color: .orange
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sensitivity")
                        .font(.headline)
                    Spacer()
                    Text(sensitivity.formatted(.number.precision(.fractionLength(2))) + " g")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $sensitivity, in: 0.03...0.5)
            }

            HStack {
                Text("X \(axis(snapshot.x))   Y \(axis(snapshot.y))   Z \(axis(snapshot.z))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset") {
                    sensor.reset()
                }
            }
        }
    }

    private func axis(_ value: Double) -> String {
        value.formatted(.number.sign(strategy: .always()).precision(.fractionLength(2)))
    }
}

private struct VibrationSnapshot {
    var x = 0.0
    var y = 0.0
    var z = 0.0
    var intensity = 0.0
    var peak = 0.0
    var knockCount = 0
    var isConnected = false
    var error: String?
}

private final class VibrationSensor: @unchecked Sendable {
    private static let noOptions = IOOptionBits(kIOHIDOptionsTypeNone)
    private let lock = NSLock()
    private var device: IOHIDDevice?
    private var reportBuffer = [UInt8](repeating: 0, count: 4096)
    private var state = VibrationSnapshot()
    private var gravity = (x: 0.0, y: 0.0, z: 0.0)
    private var hasGravity = false
    private var lastKnock = ContinuousClock.now - .seconds(1)
    private var startTime: ContinuousClock.Instant?
    private var detectionThreshold = 0.12

    var snapshot: VibrationSnapshot {
        lock.withLock {
            var snapshot = state
            if !snapshot.isConnected,
               snapshot.error == nil,
               let startTime,
               ContinuousClock.now - startTime > .seconds(3) {
                snapshot.error = "The accelerometer opened but did not provide motion data."
            }
            return snapshot
        }
    }

    var threshold: Double {
        get { lock.withLock { detectionThreshold } }
        set { lock.withLock { detectionThreshold = newValue } }
    }

    func start() {
        guard device == nil else {
            return
        }

        do {
            lock.withLock {
                startTime = .now
            }
            try enableSPU()
            try openAccelerometer()
        } catch {
            lock.withLock {
                state.error = error.localizedDescription
            }
        }
    }

    func stop() {
        guard let device else {
            return
        }
        IOHIDDeviceUnscheduleFromRunLoop(
            device,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )
        IOHIDDeviceClose(device, Self.noOptions)
        self.device = nil
    }

    func reset() {
        lock.withLock {
            state.peak = 0
            state.knockCount = 0
        }
    }

    fileprivate func handleReport(_ report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        guard length == 22 else {
            return
        }

        let x = Double(readInt32(report, offset: 6)) / 65_536
        let y = Double(readInt32(report, offset: 10)) / 65_536
        let z = Double(readInt32(report, offset: 14)) / 65_536

        lock.withLock {
            if !hasGravity {
                gravity = (x, y, z)
                hasGravity = true
            }

            let smoothing = 0.04
            gravity.x += smoothing * (x - gravity.x)
            gravity.y += smoothing * (y - gravity.y)
            gravity.z += smoothing * (z - gravity.z)

            let dx = x - gravity.x
            let dy = y - gravity.y
            let dz = z - gravity.z
            let intensity = sqrt(dx * dx + dy * dy + dz * dz)

            state.x = x
            state.y = y
            state.z = z
            state.intensity = intensity
            state.peak = max(state.peak, intensity)
            state.isConnected = true
            state.error = nil

            let now = ContinuousClock.now
            if intensity >= detectionThreshold && now - lastKnock >= .milliseconds(250) {
                state.knockCount += 1
                lastKnock = now
            }
        }
    }

    private func enableSPU() throws {
        guard let matching = IOServiceMatching("AppleSPUHIDDriver") else {
            throw VibrationError.unavailable
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            throw VibrationError.unavailable
        }
        defer { IOObjectRelease(iterator) }

        var found = false
        var service = IOIteratorNext(iterator)
        while service != 0 {
            found = true
            setProperty("SensorPropertyReportingState", value: 1, service: service)
            setProperty("SensorPropertyPowerState", value: 1, service: service)
            setProperty("ReportInterval", value: 1_000, service: service)
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        guard found else {
            throw VibrationError.unavailable
        }
    }

    private func openAccelerometer() throws {
        guard let matching = IOServiceMatching("AppleSPUHIDDevice") else {
            throw VibrationError.unavailable
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            throw VibrationError.unavailable
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            let usagePage = property("PrimaryUsagePage", service: service)
            let usage = property("PrimaryUsage", service: service)

            if usagePage == 0xFF00, usage == 3,
               let candidate = IOHIDDeviceCreate(kCFAllocatorDefault, service) {
                let result = IOHIDDeviceOpen(candidate, Self.noOptions)
                IOObjectRelease(service)
                guard result == kIOReturnSuccess else {
                    throw VibrationError.openFailed(result)
                }

                device = candidate
                let context = Unmanaged.passUnretained(self).toOpaque()
                reportBuffer.withUnsafeMutableBufferPointer { buffer in
                    IOHIDDeviceRegisterInputReportCallback(
                        candidate,
                        buffer.baseAddress!,
                        buffer.count,
                        vibrationReportCallback,
                        context
                    )
                }
                IOHIDDeviceScheduleWithRunLoop(
                    candidate,
                    CFRunLoopGetMain(),
                    CFRunLoopMode.defaultMode.rawValue
                )
                return
            }

            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        throw VibrationError.unavailable
    }

    private func setProperty(_ key: String, value: Int32, service: io_service_t) {
        var mutableValue = value
        guard let number = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &mutableValue) else {
            return
        }
        IORegistryEntrySetCFProperty(service, key as CFString, number)
    }

    private func property(_ key: String, service: io_service_t) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? NSNumber else {
            return nil
        }
        return value.intValue
    }

    private func readInt32(_ report: UnsafeMutablePointer<UInt8>, offset: Int) -> Int32 {
        let bits = UInt32(report[offset])
            | (UInt32(report[offset + 1]) << 8)
            | (UInt32(report[offset + 2]) << 16)
            | (UInt32(report[offset + 3]) << 24)
        return Int32(bitPattern: bits)
    }
}

private func vibrationReportCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    guard result == kIOReturnSuccess, let context else {
        return
    }
    let sensor = Unmanaged<VibrationSensor>.fromOpaque(context).takeUnretainedValue()
    sensor.handleReport(report, length: reportLength)
}

private enum VibrationError: LocalizedError {
    case unavailable
    case openFailed(IOReturn)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "This Mac does not expose a compatible Apple SPU accelerometer."
        case .openFailed(let code):
            "The accelerometer could not be opened (IOKit error \(code))."
        }
    }
}
