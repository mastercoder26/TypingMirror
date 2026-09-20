import Foundation

public struct Pause: Sendable, Equatable {
    public let index: Int
    public let durationMs: Double
}

public enum PauseDetector {
    /// Gaps long enough to represent deliberate thought rather than motor delay.
    public static func pauses(intervals: [Double]) -> [Pause] {
        intervals.enumerated()
            .filter { $0.element > MetricConstants.pauseMs }
            .map { Pause(index: $0.offset, durationMs: $0.element) }
    }

    /// Smaller stalls, measured relative to the typist's own median with an
    /// absolute floor so the threshold stays sane at both speed extremes.
    public static func hesitations(intervals: [Double], median: Double) -> [Pause] {
        let threshold = max(
            median * MetricConstants.hesitationMedianMultiple,
            MetricConstants.hesitationFloorMs
        )
        return intervals.enumerated()
            .filter { $0.element > threshold && $0.element <= MetricConstants.pauseMs }
            .map { Pause(index: $0.offset, durationMs: $0.element) }
    }

    public static func ratePerMinute(pauses: [Pause], activeMs: Double) -> Double {
        guard activeMs > 0 else { return 0 }
        return Double(pauses.count) / (activeMs / 60_000)
    }
}
