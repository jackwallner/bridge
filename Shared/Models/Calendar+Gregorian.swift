import Foundation

extension Calendar {
    /// Gregorian in the device's time zone.
    ///
    /// Shared identities (the month's challenge, the day's Mahj Minute) and
    /// stored day keys use it instead of `.current`, so a Buddhist, Hebrew or
    /// Japanese system calendar cannot hand a player different questions from
    /// everyone else, orphan their saved results, or stretch the challenge
    /// archive back thousands of "months". Months and days still turn over at
    /// local midnight.
    static var gregorianLocal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }
}
