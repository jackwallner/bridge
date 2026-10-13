import StoreKit
import SwiftUI
import UIKit

extension View {
    /// Calls Apple's rating prompt about three seconds after a positive moment,
    /// with no question in front of it. Bump `moment` when the moment happens
    /// (a finished drill, a finished Bridge Minute) after recording it in
    /// `ReviewPromptTracker`.
    ///
    /// Everything is checked again when the wait is over: the view must still
    /// be on screen, `isClear` must hold, and no alert or share sheet may sit on
    /// top. A blocked ask keeps the moment pending for the next one.
    func requestsReview(after moment: Int, isClear: @escaping () -> Bool = { true }) -> some View {
        modifier(ReviewRequestModifier(moment: moment, isClear: isClear))
    }
}

private struct ReviewRequestModifier: ViewModifier {
    let moment: Int
    let isClear: () -> Bool

    @Environment(\.requestReview) private var requestReview
    @State private var onScreen = false

    func body(content: Content) -> some View {
        content
            .onAppear { onScreen = true }
            .onDisappear { onScreen = false }
            .onChange(of: moment) { _, _ in schedule() }
    }

    private var eligible: Bool {
        ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: ProgressStore.shared.hasOnboarded)
    }

    private func schedule() {
        guard eligible else { return }
        Task { @MainActor in
            // Let the celebration land first.
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard onScreen, isClear(), !Self.systemSheetIsUp, eligible else { return }
            ReviewPromptTracker.markShown()
            requestReview()
        }
    }

    /// A share sheet or alert opened from the same screen is invisible to
    /// SwiftUI state, so look at what UIKit has presented on top.
    @MainActor
    private static var systemSheetIsUp: Bool {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top is UIActivityViewController || top is UIAlertController
    }
}
