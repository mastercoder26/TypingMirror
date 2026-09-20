import Foundation

public enum SessionMetricsBuilder {
    /// Number of buckets the rhythm graph draws. Fixed, so draw cost is constant
    /// whether a session ran ten seconds or forty minutes.
    public static let rhythmBuckets = 72

    public static func build(events: [TypingEvent]) -> SessionMetrics {
        let intervals = events.dropFirst().map(\.intervalMs)
        let statistics = IKIStatistics(intervals: intervals)
        let activeMs = WPMCalculator.activeMs(intervals: intervals)

        let characterCount = events.count { $0.keyClass.producesCharacter }
        let corrections = events.count { $0.keyClass.isCorrection }

        let bursts = BurstDetector.detect(intervals: intervals, baseline: statistics.p75)
        let pauses = PauseDetector.pauses(intervals: intervals)

        let correctionRate = characterCount > 0
            ? Double(corrections) / Double(characterCount)
            : 0
        let burstFraction = BurstDetector.fraction(bursts: bursts, totalKeystrokes: events.count)
        let runFraction = correctionRunFraction(events: events)

        let features = PersonalityFeatures(
            robustCV: statistics.robustCV,
            burstFraction: burstFraction,
            pauseRatePerMinute: PauseDetector.ratePerMinute(pauses: pauses, activeMs: activeMs),
            correctionRate: correctionRate,
            correctionRunFraction: runFraction,
            medianIntervalMs: statistics.median
        )

        return SessionMetrics(
            keystrokeCount: events.count,
            characterCount: characterCount,
            correctionCount: corrections,
            activeMs: activeMs,
            wallMs: intervals.reduce(0, +),
            grossWPM: WPMCalculator.gross(characterKeystrokes: characterCount, activeMs: activeMs),
            effectiveWPM: WPMCalculator.effective(
                characterKeystrokes: characterCount,
                backspaces: corrections,
                activeMs: activeMs
            ),
            peakBurstWPM: WPMCalculator.peakWindow(events: events),
            longestPauseMs: pauses.map(\.durationMs).max() ?? 0,
            pauseCount: pauses.count,
            statistics: statistics,
            burstFraction: burstFraction,
            correctionRate: correctionRate,
            correctionRunFraction: runFraction,
            features: features,
            labels: PersonalityClassifier.classify(features, keystrokes: events.count),
            rhythm: rhythm(events: events)
        )
    }

    /// Share of corrections that arrive in runs of three or more, which separates
    /// "fixed a typo" from "deleted the whole clause".
    static func correctionRunFraction(events: [TypingEvent]) -> Double {
        let total = events.count { $0.keyClass.isCorrection }
        guard total > 0 else { return 0 }

        var inRuns = 0
        var run = 0
        for event in events {
            if event.keyClass.isCorrection {
                run += 1
            } else {
                if run >= 3 { inRuns += run }
                run = 0
            }
        }
        if run >= 3 { inRuns += run }
        return Double(inRuns) / Double(total)
    }

    /// Reduces the stream to a fixed number of normalised speed buckets.
    ///
    /// Each bucket reports the *typing speed over that window* — characters
    /// divided by elapsed time — rather than any single interval. Pooling raw
    /// intervals does not work here: taking the maximum reports each window's
    /// slowest keystroke, which is nearly always slow and flattens the whole
    /// trace, while taking the minimum hides every pause.
    ///
    /// Normalisation is against the session's own 95th-percentile bucket so the
    /// trace fills the graph regardless of whether the typist runs at 30 or 100
    /// words per minute.
    static func rhythm(events: [TypingEvent]) -> [Double] {
        guard events.count > 1 else {
            return Array(repeating: 0, count: rhythmBuckets)
        }

        let perBucket = Double(events.count) / Double(rhythmBuckets)
        var speeds: [Double] = []
        speeds.reserveCapacity(rhythmBuckets)

        for bucket in 0..<rhythmBuckets {
            let low = Int(Double(bucket) * perBucket)
            let high = max(low + 1, Int(Double(bucket + 1) * perBucket))
            let slice = events[low..<min(high, events.count)]

            let elapsed = slice.reduce(0.0) { $0 + $1.intervalMs }
            let characters = slice.count { $0.keyClass.producesCharacter }
            speeds.append(
                WPMCalculator.gross(characterKeystrokes: characters, activeMs: elapsed)
            )
        }

        let ceiling = IKIStatistics.quantile(speeds.sorted(), 0.95)
        guard ceiling > 0 else { return Array(repeating: 0, count: rhythmBuckets) }
        return speeds.map { min(1, $0 / ceiling) }
    }
}
