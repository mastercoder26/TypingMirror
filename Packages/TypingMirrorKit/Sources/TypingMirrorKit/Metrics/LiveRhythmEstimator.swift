import Foundation

/// Estimates speed with a time-aware exponential moving average.
/// Updates cost O(1) per keystroke; speed decays during pauses.
public struct LiveRhythmEstimator: Sendable {
    private var emaIntervalMs: Double
    private var lastEventMs: Double = 0
    private var hasStarted = false

    public init(initialIntervalMs: Double = 250) {
        emaIntervalMs = initialIntervalMs
    }

    public mutating func ingest(atMs time: Double) {
        guard hasStarted else {
            hasStarted = true
            lastEventMs = time
            return
        }
        let delta = max(1, time - lastEventMs)
        lastEventMs = time
        let alpha = 1 - exp(-delta / MetricConstants.liveEmaTauMs)
        emaIntervalMs += alpha * (delta - emaIntervalMs)
    }

    /// Speed as of `now`, decaying toward zero while no key is pressed.
    public func instantaneousWPM(atMs now: Double) -> Double {
        guard hasStarted else { return 0 }
        let idle = max(0, now - lastEventMs)
        let decayed = emaIntervalMs
            + (1 - exp(-idle / MetricConstants.liveEmaTauMs)) * (idle - emaIntervalMs)
        return min(300, 60_000 / (MetricConstants.charactersPerWord * max(decayed, 20)))
    }
}
