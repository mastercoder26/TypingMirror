import Foundation

/// Running estimate of current typing speed.
///
/// Uses a time-aware exponential moving average over intervals rather than a
/// sliding window: it costs O(1) per keystroke, and it decays on its own during a
/// pause instead of holding a stale figure until the window rolls past.
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
