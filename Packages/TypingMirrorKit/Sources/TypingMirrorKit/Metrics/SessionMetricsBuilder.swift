import Foundation

public enum SessionMetricsBuilder {
    /// Fixed sample count for the saved rhythm graph.
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

        var correctionsInRuns = 0
        var runLength = 0
        for event in events {
            if event.keyClass.isCorrection {
                runLength += 1
            } else {
                if runLength >= 3 { correctionsInRuns += runLength }
                runLength = 0
            }
        }
        if runLength >= 3 { correctionsInRuns += runLength }
        return Double(correctionsInRuns) / Double(total)
    }

    /// Speed per window, normalized to the session's 95th-percentile bucket.
    /// Counting characters over elapsed time retains pauses without letting
    /// one unusually fast or slow interval dominate the window.
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
