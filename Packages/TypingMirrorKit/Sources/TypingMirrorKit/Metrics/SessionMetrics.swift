import Foundation

/// Everything the UI needs about one session, computed once when the session
/// closes so that no chart ever has to decode the keystroke stream.
public struct SessionMetrics: Sendable, Equatable {
    public let keystrokeCount: Int
    public let characterCount: Int
    public let correctionCount: Int
    public let activeMs: Double
    public let wallMs: Double
    public let grossWPM: Double
    public let effectiveWPM: Double
    public let peakBurstWPM: Double
    public let longestPauseMs: Double
    public let pauseCount: Int
    public let statistics: IKIStatistics
    public let burstFraction: Double
    public let correctionRate: Double
    public let correctionRunFraction: Double
    public let features: PersonalityFeatures
    public let labels: [PersonalityLabel]
    /// Downsampled rhythm, already reduced to what the graph draws.
    public let rhythm: [Double]
}
