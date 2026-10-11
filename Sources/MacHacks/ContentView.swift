import SwiftUI

struct ContentView: View {
    @AppStorage("installedHackIDs") private var installedHackIDs = ""
    @State private var route: HackRoute?
    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 250, maximum: 340), spacing: 18)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero

                    if !installedHacks.isEmpty {
                        hackSection(
                            title: "Installed",
                            subtitle: "Ready to use",
                            hacks: installedHacks
                        )
                    }

                    hackSection(
                        title: "Hack Store",
                        subtitle: "Tap a hack to install it",
                        hacks: filteredHacks
                    )
                }
                .padding(28)
            }
            .navigationTitle("Mac Hacks")
            .searchable(text: $searchText, prompt: "Search hacks")
            .sheet(item: $route) { route in
                switch route {
                case .details(let hack):
                    HackProductView(
                        hack: hack,
                        isInstalled: isInstalled(hack),
                        install: { install(hack) },
                        use: { self.route = .use(hack) }
                    )
                case .use(let hack):
                    HackRunnerView(hack: hack)
                }
            }
        }
    }

    private var hero: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Make your Mac do more.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Pick a hack, install it, and use it immediately.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "wand.and.stars.inverse")
                .font(.system(size: 46))
                .foregroundStyle(.purple)
                .padding(20)
                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.12), .blue.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var installedHacks: [HackModule] {
        HackModule.allCases.filter(isInstalled)
    }

    private var filteredHacks: [HackModule] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return HackModule.allCases
        }
        return HackModule.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.tagline.localizedCaseInsensitiveContains(query)
        }
    }

    private func hackSection(title: String, subtitle: String, hacks: [HackModule]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }

            if hacks.isEmpty {
                Text("No hacks found.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    ForEach(hacks) { hack in
                        HackStoreCard(
                            hack: hack,
                            isInstalled: isInstalled(hack),
                            action: { route = .details(hack) }
                        )
                    }
                }
            }
        }
    }

    private func isInstalled(_ hack: HackModule) -> Bool {
        Set(installedHackIDs.split(separator: ",").map(String.init)).contains(hack.rawValue)
    }

    private func install(_ hack: HackModule) {
        var installed = Set(installedHackIDs.split(separator: ",").map(String.init))
        installed.insert(hack.rawValue)
        installedHackIDs = installed.sorted().joined(separator: ",")
    }
}

private enum HackRoute: Identifiable {
    case details(HackModule)
    case use(HackModule)

    var id: String {
        switch self {
        case .details(let hack): "details-\(hack.rawValue)"
        case .use(let hack): "use-\(hack.rawValue)"
        }
    }
}

enum HackModule: String, CaseIterable, Identifiable {
    case battery
    case thermal
    case forceTouch
    case lidAngle
    case vibration
    case tuneDrop

    var id: Self { self }

    var title: String {
        switch self {
        case .battery: "Battery Monitor"
        case .thermal: "Thermal Guard"
        case .forceTouch: "Force Touch Pad"
        case .lidAngle: "Lid Angle"
        case .vibration: "Vibration Detector"
        case .tuneDrop: "TuneDrop"
        }
    }

    var tagline: String {
        switch self {
        case .battery: "See live charge, power source, and time remaining."
        case .thermal: "React automatically when your Mac gets hot."
        case .forceTouch: "Turn trackpad pressure into a live control."
        case .lidAngle: "Use the MacBook display hinge as a live input."
        case .vibration: "Detect knocks and movement through the chassis."
        case .tuneDrop: "Install and run your TuneDrop music archiver."
        }
    }

    var details: String {
        switch self {
        case .battery:
            "Adds a live dashboard for battery level, charging state, power source, and estimated remaining time."
        case .thermal:
            "Monitors macOS thermal pressure and automatically reduces polling when the system reaches serious or critical pressure."
        case .forceTouch:
            "Measures continuous trackpad pressure, remembers the peak, and counts force-click stages."
        case .lidAngle:
            "Reads the MacBook lid sensor and turns the current hinge angle into a live gauge."
        case .vibration:
            "Streams the built-in accelerometer to visualize vibration, track peaks, and count knocks."
        case .tuneDrop:
            "Installs TuneDrop through Homebrew and provides a native form for authorized music archiving."
        }
    }

    var requirement: String {
        switch self {
        case .battery: "Requires a MacBook with an internal battery."
        case .thermal: "Works on any supported Mac."
        case .forceTouch: "Requires a Force Touch trackpad."
        case .lidAngle: "Requires a MacBook that exposes Apple's lid-angle sensor."
        case .vibration: "Requires a supported Apple silicon MacBook with an exposed SPU accelerometer."
        case .tuneDrop: "Requires Homebrew, Spotify developer credentials, and permission to archive the media."
        }
    }

    var icon: String {
        switch self {
        case .battery: "battery.75percent"
        case .thermal: "thermometer.medium"
        case .forceTouch: "hand.point.up.braille"
        case .lidAngle: "laptopcomputer"
        case .vibration: "waveform.path"
        case .tuneDrop: "music.note.list"
        }
    }

    var color: Color {
        switch self {
        case .battery: .green
        case .thermal: .orange
        case .forceTouch: .purple
        case .lidAngle: .blue
        case .vibration: .pink
        case .tuneDrop: .indigo
        }
    }

    var accessNote: String {
        switch self {
        case .lidAngle, .vibration:
            "Uses an undocumented hardware interface. Compatibility depends on the Mac model and macOS release."
        case .tuneDrop:
            "Installs an external open-source command-line tool through Homebrew."
        default:
            "Uses supported macOS APIs and needs no additional download."
        }
    }

    var usesUndocumentedAccess: Bool {
        self == .lidAngle || self == .vibration
    }
}

private struct HackStoreCard: View {
    let hack: HackModule
    let isInstalled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Image(systemName: hack.icon)
                        .font(.system(size: 30))
                        .foregroundStyle(hack.color)
                        .frame(width: 56, height: 56)
                        .background(hack.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))

                    Spacer()

                    Text(isInstalled ? "USE" : "GET")
                        .font(.caption.bold())
                        .foregroundStyle(isInstalled ? .green : .accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: Capsule())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(hack.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(hack.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .padding(18)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.quaternary, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct HackProductView: View {
    @Environment(\.dismiss) private var dismiss

    let hack: HackModule
    let isInstalled: Bool
    let install: () -> Void
    let use: () -> Void

    @State private var installedDuringPresentation = false

    private var installed: Bool {
        isInstalled || installedDuringPresentation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 20) {
                Image(systemName: hack.icon)
                    .font(.system(size: 46))
                    .foregroundStyle(hack.color)
                    .frame(width: 88, height: 88)
                    .background(hack.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 7) {
                    Text(hack.title)
                        .font(.largeTitle.bold())
                    Text(hack.tagline)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            Text(hack.details)
                .font(.title3)

            Label(hack.requirement, systemImage: "desktopcomputer")
                .foregroundStyle(.secondary)

            Label(
                hack.accessNote,
                systemImage: hack.usesUndocumentedAccess ? "exclamationmark.triangle" : "checkmark.shield"
            )
            .foregroundStyle(hack.usesUndocumentedAccess ? .orange : .green)

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                if installed {
                    Button("Use Hack", action: use)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Install") {
                        install()
                        installedDuringPresentation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(30)
        .frame(width: 620, height: 420)
    }
}
