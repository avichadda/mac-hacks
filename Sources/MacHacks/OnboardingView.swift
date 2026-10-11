import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.yellow.opacity(0.16))
                        .frame(width: 86, height: 86)
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.yellow)
                }

                Text("Welcome to Mac Hacks")
                    .font(.largeTitle.bold())

                Text("Install useful hardware hacks and run them immediately\nfrom one simple app.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .top, spacing: 16) {
                OnboardingFeature(
                    icon: "hand.tap",
                    color: .blue,
                    title: "Tap a Hack",
                    description: "Choose a working hack from the store."
                )
                OnboardingFeature(
                    icon: "arrow.down.circle",
                    color: .green,
                    title: "Install",
                    description: "Enable it locally with one click and no extra download."
                )
                OnboardingFeature(
                    icon: "play.circle",
                    color: .orange,
                    title: "Use",
                    description: "Launch working hardware hacks and tools directly from Mac Hacks."
                )
            }

            Button(action: onComplete) {
                Text("Open the Hack Store")
                    .frame(minWidth: 180)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(width: 720, height: 500)
        .background {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
    }
}

private struct OnboardingFeature: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .frame(height: 34)

            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .top)
        .padding(18)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
    }
}
