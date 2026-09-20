import Foundation

/// A run of keystrokes fast relative to this typist.
public struct Burst: Sendable, Equatable {
    public let startIndex: Int
    public let length: Int
    public let elapsedMs: Double

    public var wpm: Double {
        WPMCalculator.gross(characterKeystrokes: length, activeMs: elapsedMs)
    }
}

public enum BurstDetector {
    /// Finds maximal runs of at least `burstMinimumRun` keystrokes whose intervals
    /// all sit under a fraction of `baseline` — the typist's cruising pace.
    ///
    /// The threshold is relative rather than absolute so that "burst" means *fast
    /// for you*: a 40 WPM typist has bursts just as a 120 WPM typist does.
    public static func detect(intervals: [Double], baseline: Double) -> [Burst] {
        guard baseline > 0, !intervals.isEmpty else { return [] }
        let threshold = baseline * MetricConstants.burstIntervalFraction

        var bursts: [Burst] = []
        var runStart = 0
        var runLength = 0
        var runMs = 0.0

        func closeRun(endingAt index: Int) {
            if runLength >= MetricConstants.burstMinimumRun {
                bursts.append(Burst(startIndex: runStart, length: runLength, elapsedMs: runMs))
            }
            runLength = 0
            runMs = 0
            runStart = index
        }

        for (index, interval) in intervals.enumerated() {
            if interval <= threshold {
                if runLength == 0 { runStart = index }
                runLength += 1
                runMs += interval
            } else {
                closeRun(endingAt: index + 1)
            }
        }
        closeRun(endingAt: intervals.count)
        return bursts
    }

    /// Share of keystrokes that fall inside a burst.
    public static func fraction(bursts: [Burst], totalKeystrokes: Int) -> Double {
        guard totalKeystrokes > 0 else { return 0 }
        return Double(bursts.reduce(0) { $0 + $1.length }) / Double(totalKeystrokes)
    }
}
