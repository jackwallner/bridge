import SwiftUI

struct RootView: View {
    // Same defaults key ProgressStore.hasOnboarded writes, so finishing
    // onboarding flips this live. Branching (not a cover) means Home never
    // flashes behind onboarding on first launch.
    @AppStorage("progress.hasOnboarded") private var hasOnboarded = false

    var body: some View {
        ZStack {
            if hasOnboarded {
                HomeView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasOnboarded)
    }
}
