import SwiftUI

struct HackRunnerView: View {
    @Environment(\.dismiss) private var dismiss
    let hack: HackModule

    var body: some View {
        NavigationStack {
            Group {
                switch hack {
                case .battery:
                    BatteryHackView()
                case .thermal:
                    ThermalHackView()
                case .forceTouch:
                    ForceTouchHackView()
                case .lidAngle:
                    LidAngleHackView()
                case .vibration:
                    VibrationHackView()
                case .tuneDrop:
                    TuneDropHackView()
                }
            }
            .navigationTitle(hack.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 840, height: 560)
    }
}

struct ModuleHeader: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
                .frame(width: 54, height: 54)
                .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title.bold())
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}
