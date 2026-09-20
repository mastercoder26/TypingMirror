import Foundation

/// A day's typing, aggregated from its sessions.
public struct DailySummary: Sendable, Identifiable, Equatable {
    public let id: Int
    /// Local calendar day as yyyyMMdd, so days sort and join without date maths.
    public var dayKey: Int { id }
    public let date: Date
    public let sessionCount: Int
    public let totalKeystrokes: Int
    public let totalActiveMs: Double
    public let medianIntervalMs: Double
    public let robustCV: Double
    public let burstFraction: Double
    public let correctionRate: Double
    public let pauseRatePerMinute: Double
    public let peakHour: Int
    public let distinctCategories: Int
    /// Share of the day's keystrokes falling in each hour.
    public let hourlyShare: [Double]

    public var averageWPM: Double {
        WPMCalculator.gross(
            characterKeystrokes: Int(Double(totalKeystrokes) * 0.93),
            activeMs: totalActiveMs
        )
    }
}

public enum DailySummaryBuilder {
    public static func dayKey(for date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return (parts.year ?? 0) * 10_000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
    }

    /// Groups sessions into days, weighting each day's rhythm figures by how much
    /// typing each session contributed.
    public static func build(
        sessions: [TypingSession],
        calendar: Calendar = .current
    ) -> [DailySummary] {
        let groups = Dictionary(grouping: sessions) { dayKey(for: $0.startedAt, calendar: calendar) }

        return groups.map { key, daySessions in
            let keystrokes = daySessions.reduce(0) { $0 + $1.metrics.keystrokeCount }
            let weight = max(1, keystrokes)

            func weighted(_ value: (SessionMetrics) -> Double) -> Double {
                daySessions.reduce(0) {
                    $0 + value($1.metrics) * Double($1.metrics.keystrokeCount)
                } / Double(weight)
            }

            var hourly = [Double](repeating: 0, count: 24)
            for session in daySessions {
                let hour = calendar.component(.hour, from: session.startedAt)
                hourly[hour] += Double(session.metrics.keystrokeCount)
            }
            let hourlyTotal = max(1, hourly.reduce(0, +))
            hourly = hourly.map { $0 / hourlyTotal }

            let activeMs = daySessions.reduce(0) { $0 + $1.metrics.activeMs }
            let pauses = daySessions.reduce(0) { $0 + $1.metrics.pauseCount }

            return DailySummary(
                id: key,
                date: daySessions[0].startedAt,
                sessionCount: daySessions.count,
                totalKeystrokes: keystrokes,
                totalActiveMs: activeMs,
                medianIntervalMs: weighted { $0.statistics.median },
                robustCV: weighted { $0.statistics.robustCV },
                burstFraction: weighted { $0.burstFraction },
                correctionRate: weighted { $0.correctionRate },
                pauseRatePerMinute: activeMs > 0 ? Double(pauses) / (activeMs / 60_000) : 0,
                peakHour: hourly.firstIndex(of: hourly.max() ?? 0) ?? 0,
                distinctCategories: Set(daySessions.map(\.category)).count,
                hourlyShare: hourly
            )
        }
        .sorted { $0.dayKey > $1.dayKey }
    }
}
