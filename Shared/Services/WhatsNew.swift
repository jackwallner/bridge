import Foundation

/// One line on the What's New sheet.
struct WhatsNewItem: Identifiable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    /// Marks the line as membership content, so the sheet can badge it and a
    /// free player can see exactly what the upgrade would hand them.
    let isPlus: Bool

    init(id: String, icon: String, title: String, body: String, isPlus: Bool = false) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.isPlus = isPlus
    }
}

struct WhatsNewRelease: Sendable {
    let version: String
    let headline: String
    let items: [WhatsNewItem]
}

/// Decides whether to show the post-update What's New sheet, and remembers
/// that it has been shown.
///
/// The rule that matters: a FRESH install never sees it. Onboarding already
/// introduces the app, and opening a brand-new download with "here's what
/// changed" is nonsense. Only a player who had an older version installed gets
/// the sheet, once, on the first launch after updating.
enum WhatsNew {

    static let currentVersion: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

    private static let lastSeenKey = "whatsnew.lastSeenVersion"

    static let releases: [WhatsNewRelease] = [
        WhatsNewRelease(
            version: "1.1",
            headline: "Practice that never runs out",
            items: [
                WhatsNewItem(
                    id: "endless",
                    icon: "infinity",
                    title: "Endless Practice",
                    body: "Freshly dealt hands, every time. Name the opening call or count the points for as long as you like, with a full explanation after every answer.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "review",
                    icon: "arrow.trianglehead.counterclockwise",
                    title: "Fix My Mistakes",
                    body: "The app now remembers what you get wrong and brings it back on a schedule, so the weak spots actually close instead of piling up.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "challenge",
                    icon: "timer",
                    title: "Timed Challenge",
                    body: "Ninety seconds, as many correct calls as you can manage, and a personal best to chase.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "stats",
                    icon: "chart.bar.fill",
                    title: "Your progress, in detail",
                    body: "Accuracy for every room, your weakest area, and how much you have practised overall."
                ),
                WhatsNewItem(
                    id: "content",
                    icon: "plus.rectangle.on.folder.fill",
                    title: "More drills in every room",
                    body: "New hand-written questions across the auction, declarer play, defense, and the Master Tables."
                ),
            ]
        )
    ]

    static var currentRelease: WhatsNewRelease? {
        releases.first { $0.version == currentVersion }
    }

    /// True when this launch is the first one after an update and there are
    /// notes to show for the version now running.
    static func shouldPresent(hasOnboarded: Bool, defaults: UserDefaults = .standard) -> Bool {
        guard hasOnboarded, currentRelease != nil else { return false }
        let lastSeen = defaults.string(forKey: lastSeenKey) ?? ""
        // An empty marker on an onboarded player means they updated from a
        // build that predates this feature. That is exactly the audience.
        return lastSeen != currentVersion
    }

    static func markSeen(defaults: UserDefaults = .standard) {
        defaults.set(currentVersion, forKey: lastSeenKey)
    }

    /// Called when onboarding finishes so a new player is never shown notes
    /// for a version they have only ever run.
    static func markCurrentAsBaseline(defaults: UserDefaults = .standard) {
        defaults.set(currentVersion, forKey: lastSeenKey)
    }
}
