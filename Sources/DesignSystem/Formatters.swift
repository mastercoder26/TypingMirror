import Foundation

public enum Fmt {
    /// "18m 42s", or "42s" when under a minute.
    public static func duration(ms: Double) -> String {
        let total = Int(ms / 1000)
        let minutes = total / 60
        let seconds = total % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }

    public static func wpm(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    /// One decimal place, for pause lengths where tenths carry meaning.
    public static func seconds(ms: Double) -> String {
        String(format: "%.1f", ms / 1000)
    }

    public static func percent(_ fraction: Double) -> String {
        String(Int((fraction * 100).rounded()))
    }

    public static func relativeDay(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month().day())
    }

    public static func clockTime(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}
