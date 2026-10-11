import SwiftUI

struct ThermalHackView: View {
    @State private var automationEnabled = true
    @State private var thermalState = ProcessInfo.processInfo.thermalState

    var body: some View {
        let status = ThermalStatus(thermalState)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ModuleHeader(
                    icon: "thermometer.medium",
                    color: status.color,
                    title: "Thermal-State Automation",
                    description: "Monitors macOS thermal pressure using ProcessInfo and reacts when the system is under stress."
                )

                HStack(spacing: 14) {
                    MetricCard(
                        title: "Current State",
                        value: status.title,
                        systemImage: status.icon,
                        color: status.color
                    )
                    MetricCard(
                        title: "Recommended Action",
                        value: status.action,
                        systemImage: "gearshape.2",
                        color: status.color
                    )
                }

                Toggle("Automatically reduce polling during serious thermal pressure", isOn: $automationEnabled)
                    .toggleStyle(.switch)

                HStack(spacing: 14) {
                    Image(systemName: lowImpactActive ? "leaf.fill" : "leaf")
                        .font(.system(size: 28))
                        .foregroundStyle(lowImpactActive ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lowImpactActive ? "Low-impact mode is active" : "Normal operation")
                            .font(.headline)
                        Text(automationDescription)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    (lowImpactActive ? Color.green : Color.secondary).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 12)
                )

                Text("macOS reports a thermal pressure level rather than individual sensor temperatures through its public API.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(30)
        }
        .task(id: automationEnabled) {
            await monitorThermalState()
        }
    }

    private var lowImpactActive: Bool {
        guard automationEnabled else {
            return false
        }
        return thermalState == .serious || thermalState == .critical
    }

    private var automationDescription: String {
        if !automationEnabled {
            return "Automatic response is disabled."
        }
        if lowImpactActive {
            return "Polling is reduced from every 2 seconds to every 10 seconds while the Mac cools down."
        }
        return "The app will react automatically if thermal pressure reaches Serious or Critical."
    }

    @MainActor
    private func monitorThermalState() async {
        while !Task.isCancelled {
            thermalState = ProcessInfo.processInfo.thermalState
            let interval: Duration = lowImpactActive ? .seconds(10) : .seconds(2)

            do {
                try await Task.sleep(for: interval)
            } catch is CancellationError {
                return
            } catch {
                assertionFailure("Thermal monitor sleep failed: \(error.localizedDescription)")
                return
            }
        }
    }
}

private struct ThermalStatus {
    let title: String
    let action: String
    let icon: String
    let color: Color

    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal:
            title = "Nominal"
            action = "None"
            icon = "thermometer.low"
            color = .green
        case .fair:
            title = "Fair"
            action = "Monitor"
            icon = "thermometer.medium"
            color = .yellow
        case .serious:
            title = "Serious"
            action = "Reduce Work"
            icon = "thermometer.high"
            color = .orange
        case .critical:
            title = "Critical"
            action = "Pause Work"
            icon = "exclamationmark.triangle.fill"
            color = .red
        @unknown default:
            title = "Unknown"
            action = "Monitor"
            icon = "questionmark.circle"
            color = .secondary
        }
    }
}
