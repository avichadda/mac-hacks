import IOKit.ps
import SwiftUI

struct BatteryHackView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { _ in
            let snapshot = BatterySnapshot.read()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ModuleHeader(
                        icon: "battery.75percent",
                        color: .green,
                        title: "Live Battery Monitor",
                        description: "Reads battery and power-source information using Apple's public IOPowerSources API."
                    )

                    switch snapshot {
                    case .success(let battery):
                        BatteryDashboard(snapshot: battery)
                    case .failure(let error):
                        ModuleUnavailable(
                            title: "Battery data unavailable",
                            description: error.localizedDescription
                        )
                    }
                }
                .padding(30)
            }
        }
    }
}

private struct BatteryDashboard: View {
    let snapshot: BatterySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                MetricCard(
                    title: "Charge",
                    value: "\(snapshot.percentage)%",
                    systemImage: batteryIcon,
                    color: chargeColor
                )
                MetricCard(
                    title: "Power Source",
                    value: snapshot.powerSource,
                    systemImage: snapshot.isOnACPower ? "powerplug" : "bolt",
                    color: .blue
                )
                MetricCard(
                    title: snapshot.isCharging ? "Until Full" : "Remaining",
                    value: snapshot.timeDescription,
                    systemImage: "clock",
                    color: .orange
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(snapshot.status)
                        .font(.headline)
                    Spacer()
                    Text("Updates every 5 seconds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(snapshot.percentage), total: 100)
                    .tint(chargeColor)
            }
            .padding(18)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var batteryIcon: String {
        if snapshot.isCharging {
            return "battery.100percent.bolt"
        }
        switch snapshot.percentage {
        case 76...: return "battery.100percent"
        case 51...: return "battery.75percent"
        case 26...: return "battery.50percent"
        case 11...: return "battery.25percent"
        default: return "battery.0percent"
        }
    }

    private var chargeColor: Color {
        switch snapshot.percentage {
        case 21...: .green
        case 11...: .orange
        default: .red
        }
    }
}

private struct BatterySnapshot {
    let percentage: Int
    let isCharging: Bool
    let isOnACPower: Bool
    let minutesRemaining: Int?

    var powerSource: String {
        isOnACPower ? "Power Adapter" : "Battery"
    }

    var status: String {
        if isCharging {
            return "Charging"
        }
        if isOnACPower {
            return "Connected to power"
        }
        return "Running on battery"
    }

    var timeDescription: String {
        guard let minutesRemaining, minutesRemaining > 0 else {
            return "Calculating"
        }
        let hours = minutesRemaining / 60
        let minutes = minutesRemaining % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    static func read() -> Result<BatterySnapshot, BatteryReadError> {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(info, source)?
                .takeUnretainedValue() as? [String: Any] else {
            return .failure(
                BatteryReadError(
                    message: "No internal battery was reported. This module is intended for MacBook models."
                )
            )
        }

        let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maximum = description[kIOPSMaxCapacityKey] as? Int ?? 100
        guard maximum > 0 else {
            return .failure(BatteryReadError(message: "The battery reported an invalid maximum capacity."))
        }

        let percentage = min(max(Int((Double(current) / Double(maximum) * 100).rounded()), 0), 100)
        let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
        let state = description[kIOPSPowerSourceStateKey] as? String
        let isOnACPower = state == kIOPSACPowerValue
        let timeKey = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        let time = description[timeKey] as? Int

        return .success(
            BatterySnapshot(
                percentage: percentage,
                isCharging: isCharging,
                isOnACPower: isOnACPower,
                minutesRemaining: time
            )
        )
    }
}

private struct BatteryReadError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

struct ModuleUnavailable: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(description)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding()
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
}
