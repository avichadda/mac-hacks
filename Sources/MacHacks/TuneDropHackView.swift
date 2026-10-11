import AppKit
import SwiftUI

struct TuneDropHackView: View {
    @State private var executable = TuneDropCommand.locate()
    @State private var spotifyURL = ""
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var outputDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Music/TuneDrop")
    @State private var format = "mp3"
    @State private var confirmsAuthorization = false
    @State private var isWorking = false
    @State private var output = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ModuleHeader(
                    icon: "music.note.list",
                    color: .indigo,
                    title: "TuneDrop",
                    description: "Archive music you are authorized to access using Spotify metadata and TuneDrop."
                )

                if executable == nil {
                    installer
                } else {
                    archiveForm
                }
            }
            .padding(30)
        }
    }

    private var installer: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("TuneDrop is not installed", systemImage: "arrow.down.circle")
                .font(.title2.bold())

            Text("Mac Hacks can install TuneDrop and FFmpeg through Homebrew. The command output will be shown here.")
                .foregroundStyle(.secondary)

            Button("Install TuneDrop") {
                install()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking)

            if isWorking {
                ProgressView("Installing with Homebrew...")
            }

            commandOutput
        }
        .padding(22)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }

    private var archiveForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Spotify metadata") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Spotify track, album, or playlist URL", text: $spotifyURL)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Spotify client ID", text: $clientID)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Spotify client secret", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                    Text("Credentials are passed only to the TuneDrop process and are not saved by Mac Hacks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }

            GroupBox("Output") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(outputDirectory.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Choose Folder") {
                            chooseOutputDirectory()
                        }
                    }

                    Picker("Format", selection: $format) {
                        Text("MP3").tag("mp3")
                        Text("M4A").tag("m4a")
                        Text("FLAC").tag("flac")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(8)
            }

            Toggle(
                "I confirm I own this media or have permission to download and archive it.",
                isOn: $confirmsAuthorization
            )

            HStack {
                Button("Open Spotify Developer Dashboard") {
                    NSWorkspace.shared.open(URL(string: "https://developer.spotify.com/dashboard")!)
                }

                Spacer()

                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("Run TuneDrop") {
                    runTuneDrop()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canRun)
            }

            commandOutput
        }
    }

    @ViewBuilder
    private var commandOutput: some View {
        if !output.isEmpty {
            ScrollView {
                Text(output)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(minHeight: 90, maxHeight: 180)
            .background(.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var canRun: Bool {
        executable != nil
            && !spotifyURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !clientID.isEmpty
            && !clientSecret.isEmpty
            && confirmsAuthorization
            && !isWorking
    }

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = outputDirectory
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url
        }
    }

    private func install() {
        guard let brew = TuneDropCommand.locateHomebrew() else {
            output = "Homebrew was not found. Install it from https://brew.sh and try again."
            return
        }

        isWorking = true
        output = "Installing TuneDrop...\n"

        Task {
            let tap = await Task.detached {
                TuneDropCommand.run(
                    executable: brew,
                    arguments: [
                        "tap",
                        "avichadda/tunedrop",
                        "https://github.com/avichadda/tunedrop"
                    ]
                )
            }.value

            guard tap.exitCode == 0 else {
                output = tap.displayOutput
                isWorking = false
                return
            }

            let runtime = await Task.detached {
                TuneDropCommand.run(
                    executable: brew,
                    arguments: ["install", "deno"]
                )
            }.value

            guard runtime.exitCode == 0 else {
                output = tap.displayOutput + "\n" + runtime.displayOutput
                isWorking = false
                return
            }

            let installation = await Task.detached {
                TuneDropCommand.run(
                    executable: brew,
                    arguments: ["install", "--HEAD", "avichadda/tunedrop/tunedrop"]
                )
            }.value

            output = [
                tap.displayOutput,
                runtime.displayOutput,
                installation.displayOutput
            ].joined(separator: "\n")
            executable = installation.exitCode == 0 ? TuneDropCommand.locate() : nil
            isWorking = false
        }
    }

    private func runTuneDrop() {
        guard let executable else {
            output = "TuneDrop is not installed."
            return
        }

        isWorking = true
        output = "Running TuneDrop...\n"
        let arguments = [
            "--output", outputDirectory.path,
            "--format", format,
            spotifyURL.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        let credentials = [
            "tunedrop_client_id": clientID,
            "tunedrop_client_secret": clientSecret
        ]

        Task {
            let result = await Task.detached {
                TuneDropCommand.run(
                    executable: executable,
                    arguments: arguments,
                    additionalEnvironment: credentials
                )
            }.value

            output = result.displayOutput
            isWorking = false
        }
    }
}

private struct TuneDropCommand {
    struct Result: Sendable {
        let exitCode: Int32
        let standardOutput: String
        let standardError: String

        var displayOutput: String {
            let combined = [standardOutput, standardError]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            return combined.isEmpty ? "Command finished with exit code \(exitCode)." : combined
        }
    }

    static func locate() -> URL? {
        [
            "/opt/homebrew/bin/tunedrop",
            "/usr/local/bin/tunedrop"
        ]
        .map(URL.init(fileURLWithPath:))
        .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    static func locateHomebrew() -> URL? {
        [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew"
        ]
        .map(URL.init(fileURLWithPath:))
        .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    static func run(
        executable: URL,
        arguments: [String],
        additionalEnvironment: [String: String] = [:]
    ) -> Result {
        let process = Process()
        let combinedOutput = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = combinedOutput
        process.standardError = combinedOutput
        var environment = ProcessInfo.processInfo.environment.merging(
            additionalEnvironment,
            uniquingKeysWith: { _, new in new }
        )
        let homebrewPaths = ["/opt/homebrew/bin", "/usr/local/bin"]
        let existingPath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = (homebrewPaths + [existingPath]).joined(separator: ":")
        process.environment = environment

        do {
            try process.run()
            let outputData = combinedOutput.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return Result(
                exitCode: process.terminationStatus,
                standardOutput: String(decoding: outputData, as: UTF8.self),
                standardError: ""
            )
        } catch {
            return Result(
                exitCode: -1,
                standardOutput: "",
                standardError: "Could not launch \(executable.lastPathComponent): \(error.localizedDescription)"
            )
        }
    }
}
