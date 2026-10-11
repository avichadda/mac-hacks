import SwiftUI

@main
struct MacHacksApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 500)
                .sheet(isPresented: onboardingPresented) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                    .interactiveDismissDisabled()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            SidebarCommands()
            CommandGroup(after: .help) {
                Button("Show Welcome") {
                    hasCompletedOnboarding = false
                }
            }
        }
    }

    private var onboardingPresented: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { isPresented in
                if !isPresented {
                    hasCompletedOnboarding = true
                }
            }
        )
    }
}
