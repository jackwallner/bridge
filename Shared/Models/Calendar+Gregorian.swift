import Foundation

extension Calendar {
    /// Gregorian in the device's time zone.
    ///
    /// Shared identities (the month's challenge, the day's Bridge Minute) and
    /// stored day keys use it instead of `.current`, so a Buddhist, Hebrew or
    /// Japanese system calendar cannot hand a player different questions from
    /// everyone else, orphan their saved results, or stretch the challenge
    /// archive back thousands of "months". Months and days still turn over at
    /// local midnight.
    ///
    /// The zone comes from `Calendar.current`, which follows a time-zone
    /// change; `TimeZone.current` stays cached at the zone the process saw first.
    static var gregorianLocal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Calendar.current.timeZone
        return calendar
    }
}
