import Testing
@testable import TypingMirrorKit

@Suite("Interval statistics")
struct IKIStatisticsTests {
    @Test("median resists a single extreme pause")
    func medianResistsOutlier() {
        // Arrange: nine tight intervals and one 30-second stare.
        let intervals = Array(repeating: 200.0, count: 9) + [30_000]

        // Act
        let stats = IKIStatistics(intervals: intervals)

        // Assert: the mean would be ~3180ms, which describes no real keystroke.
        #expect(stats.median == 200)
    }

    @Test("robust CV is zero for a perfectly even rhythm")
    func evenRhythmHasNoVariation() {
        let stats = IKIStatistics(intervals: Array(repeating: 180.0, count: 50))
        #expect(stats.robustCV == 0)
    }

    @Test("robust CV rises with irregularity")
    func irregularRhythmScoresHigher() {
        let even = IKIStatistics(intervals: Array(repeating: 180.0, count: 40))
        let uneven = IKIStatistics(intervals: (0..<40).map { $0.isMultiple(of: 2) ? 90.0 : 400.0 })
        #expect(uneven.robustCV > even.robustCV)
    }

    @Test("empty input does not trap")
    func emptyIsSafe() {
        let stats = IKIStatistics(intervals: [])
        #expect(stats.count == 0)
        #expect(stats.robustCV == 0)
    }
}

@Suite("Words per minute")
struct WPMCalculatorTests {
    @Test("gross WPM uses the five-character word convention")
    func grossUsesFiveCharacterWords() {
        // 500 characters in exactly one minute is 100 words.
        let wpm = WPMCalculator.gross(characterKeystrokes: 500, activeMs: 60_000)
        #expect(abs(wpm - 100) < 0.001)
    }

    @Test("idle time is excluded from active time")
    func idleGapsAreExcluded() {
        // One 60s gap plus ten 100ms intervals: only the short ones count.
        let intervals = [60_000.0] + Array(repeating: 100.0, count: 10)
        #expect(WPMCalculator.activeMs(intervals: intervals) == 1_000)
    }

    @Test("effective WPM charges each backspace twice")
    func backspacesAreChargedTwice() {
        let effective = WPMCalculator.effective(
            characterKeystrokes: 500, backspaces: 50, activeMs: 60_000
        )
        // 500 - 2*50 = 400 characters = 80 words.
        #expect(abs(effective - 80) < 0.001)
    }

    @Test("effective WPM floors at zero rather than going negative")
    func effectiveNeverNegative() {
        let effective = WPMCalculator.effective(
            characterKeystrokes: 10, backspaces: 40, activeMs: 60_000
        )
        #expect(effective == 0)
    }

    @Test("zero active time yields zero, not a divide by zero")
    func zeroActiveTimeIsSafe() {
        #expect(WPMCalculator.gross(characterKeystrokes: 100, activeMs: 0) == 0)
    }
}

@Suite("Burst detection")
struct BurstDetectorTests {
    @Test("a run of fast keystrokes is detected")
    func detectsFastRun() {
        // Baseline 200 puts the burst threshold at 110.
        let intervals = Array(repeating: 200.0, count: 20)
            + Array(repeating: 80.0, count: 8)
            + Array(repeating: 200.0, count: 20)

        let bursts = BurstDetector.detect(intervals: intervals, baseline: 200)

        #expect(bursts.count == 1)
        #expect(bursts.first?.length == 8)
    }

    @Test("runs shorter than the minimum are ignored")
    func ignoresShortRuns() {
        let intervals = Array(repeating: 200.0, count: 10)
            + Array(repeating: 80.0, count: 3)
            + Array(repeating: 200.0, count: 10)
        #expect(BurstDetector.detect(intervals: intervals, baseline: 200).isEmpty)
    }

    @Test("burst threshold is relative, so a slow typist still has bursts")
    func thresholdIsRelative() {
        // A 500ms-baseline typist bursting at 200ms is fast *for them*.
        let intervals = Array(repeating: 500.0, count: 10)
            + Array(repeating: 200.0, count: 8)
        let bursts = BurstDetector.detect(intervals: intervals, baseline: 500)
        #expect(bursts.count == 1)
    }
}

@Suite("Pause detection")
struct PauseDetectorTests {
    @Test("gaps over two seconds count as pauses")
    func detectsLongPauses() {
        let intervals = [150.0, 180.0, 3_500.0, 160.0, 12_400.0]
        let pauses = PauseDetector.pauses(intervals: intervals)
        #expect(pauses.count == 2)
        #expect(pauses.map(\.durationMs).max() == 12_400)
    }

    @Test("hesitations sit between the relative threshold and a full pause")
    func hesitationsExcludeRealPauses() {
        // Median 150 puts the hesitation threshold at 450ms.
        let intervals = [150.0, 600.0, 5_000.0]
        let hesitations = PauseDetector.hesitations(intervals: intervals, median: 150)
        #expect(hesitations.count == 1)
        #expect(hesitations.first?.durationMs == 600)
    }
}


@Suite("Burst baseline")
struct BurstBaselineTests {
    /// Regression guard. The threshold was once anchored to the median, which
    /// collapsed for a heavily bursty typist: their bursts dominated the
    /// distribution, dragged the median down, and pushed the threshold below the
    /// very runs it was meant to catch.
    @Test("a typist who bursts constantly still registers bursts")
    func burstDominatedSessionStillDetectsBursts() {
        // Arrange: two thirds of this session is spent bursting at 80ms.
        let intervals = Array(repeating: 80.0, count: 200)
            + Array(repeating: 300.0, count: 100)
        let stats = IKIStatistics(intervals: intervals)

        // Act
        let viaMedian = BurstDetector.detect(intervals: intervals, baseline: stats.median)
        let viaCruisingPace = BurstDetector.detect(intervals: intervals, baseline: stats.p75)

        // Assert: the median has been pulled into the burst population.
        #expect(viaMedian.isEmpty)
        #expect(!viaCruisingPace.isEmpty)
    }

    @Test("p75 tracks the relaxed pace, not the burst pace")
    func p75TracksCruisingPace() {
        let intervals = Array(repeating: 80.0, count: 200)
            + Array(repeating: 300.0, count: 100)
        let stats = IKIStatistics(intervals: intervals)
        #expect(stats.median == 80)
        #expect(stats.p75 == 300)
    }
}
