import Foundation

/// When a result screen may raise the one-tap trial sheet on its own.
///
/// Ported from Mahj Trainer (Jack, 2026-11-24). A free player who said "not
/// now" on the onboarding trial page meets the trial again at a good moment,
/// one tap from Apple's sheet. Paced by app session on install day and the day
/// after, then by days, because trials are front-loaded: RevenueCat puts 78 to
/// 90 percent of trial starts on install day. In those two days a player can
/// see it once per visit, three times a day at most (after their second
/// practice of their own), and after that at most once in 3 days, then 7, then
/// every 14 for as long as they play.
/// A tap on a Bridge+ card is the player asking, so it ignores this pacing;
/// `trial_offer: off` stops the automatic asks without a release.
enum TrialOfferPacer {
    /// Practices of their own before the first automatic ask.
    static let practicesBeforeFirstAsk = 2
    /// Install day and the next: once per app session.
    static let sessionPacedDays = 2
    /// Most asks in one of those days.
    static let sessionPacedDailyCap = 3
    /// After that, the wait since the last ask, by how many came before.
    static let dayGaps: [TimeInterval] = [3, 7, 14].map { $0 * 24 * 60 * 60 }
    /// Back after this long away counts as a new session.
    static let sessionBreak: TimeInterval = 30 * 60

    static let lastShownKey = "trialOffer.lastAutoShown"
    static let lastShownSessionKey = "trialOffer.lastAutoShownSession"
    static let dayPacedCountKey = "trialOffer.dayPacedCount"
    static let sessionKey = "trialOffer.session"
    /// Automatic asks waiting on StoreKit's eligibility answer (a count, so
    /// two overlapping checks never clear each other). Main actor only.
    nonisolated(unsafe) static var autoOffersPending = 0
    static let leftAtKey = "trialOffer.leftAt"
    static let askDayKey = "trialOffer.askDay"
    static let askDayCountKey = "trialOffer.askDayCount"

    static func autoOfferDue(
        practicesSinceOnboarding: Int,
        installedAt: Date?,
        now: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard practicesSinceOnboarding >= practicesBeforeFirstAsk else { return false }
        if isSessionPaced(installedAt: installedAt, now: now, calendar: calendar) {
            guard asksToday(now: now, calendar: calendar, defaults: defaults) < sessionPacedDailyCap else { return false }
            guard defaults.object(forKey: lastShownSessionKey) != nil else { return true }
            return defaults.integer(forKey: lastShownSessionKey) < defaults.integer(forKey: sessionKey)
        }
        // A stamp from a clock that ran ahead is in the future: treat it as unset.
        guard let last = defaults.object(forKey: lastShownKey) as? Date, last <= now else { return true }
        let gap = dayGaps[min(defaults.integer(forKey: dayPacedCountKey), dayGaps.count - 1)]
        return now.timeIntervalSince(last) >= gap
    }

    static func markAutoShown(
        installedAt: Date?,
        now: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(asksToday(now: now, calendar: calendar, defaults: defaults) + 1, forKey: askDayCountKey)
        defaults.set(calendar.startOfDay(for: now), forKey: askDayKey)
        defaults.set(now, forKey: lastShownKey)
        defaults.set(defaults.integer(forKey: sessionKey), forKey: lastShownSessionKey)
        if !isSessionPaced(installedAt: installedAt, now: now, calendar: calendar) {
            defaults.set(defaults.integer(forKey: dayPacedCountKey) + 1, forKey: dayPacedCountKey)
        }
    }

    static func asksToday(now: Date, calendar: Calendar = .current, defaults: UserDefaults = .standard) -> Int {
        guard let day = defaults.object(forKey: askDayKey) as? Date,
              calendar.isDate(day, inSameDayAs: now) else { return 0 }
        return defaults.integer(forKey: askDayCountKey)
    }

    /// Install day or the calendar day after it.
    static func isSessionPaced(installedAt: Date?, now: Date, calendar: Calendar = .current) -> Bool {
        calendarDays(from: installedAt ?? now, to: now, calendar: calendar) < sessionPacedDays
    }

    /// Whole calendar days between two instants, counted noon to noon so a
    /// daylight-saving change or a zone with no midnight never miscounts.
    static func calendarDays(from start: Date, to end: Date, calendar: Calendar) -> Int {
        func noon(_ date: Date) -> Date {
            var parts = calendar.dateComponents([.year, .month, .day], from: date)
            parts.hour = 12
            return calendar.date(from: parts) ?? date
        }
        return calendar.dateComponents([.day], from: noon(start), to: noon(end)).day ?? 0
    }

    /// The app came to the foreground. A first launch, or a return after
    /// `sessionBreak` away, starts a new session. Safe to call twice for one
    /// return (launch and scene phase both report it).
    static func noteForeground(now: Date = Date(), defaults: UserDefaults = .standard) {
        let session = defaults.integer(forKey: sessionKey)
        guard let left = defaults.object(forKey: leftAtKey) as? Date else {
            if session == 0 { defaults.set(1, forKey: sessionKey) }
            return
        }
        defaults.removeObject(forKey: leftAtKey)
        if now.timeIntervalSince(left) >= sessionBreak { defaults.set(session + 1, forKey: sessionKey) }
    }

    static func noteBackground(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: leftAtKey)
    }

    /// True right after an automatic ask, so the rating prompt does not land
    /// on the same result: one ask per moment.
    static func autoShownRecently(within seconds: TimeInterval = 120, now: Date = Date(),
                                  defaults: UserDefaults = .standard) -> Bool {
        // An automatic ask still waiting on StoreKit's free-week answer
        // counts: the rating prompt must not land first and be covered.
        if autoOffersPending > 0 { return true }
        guard let last = defaults.object(forKey: lastShownKey) as? Date, last <= now else { return false }
        return now.timeIntervalSince(last) < seconds
    }
}
