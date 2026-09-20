import Testing
@testable import TypingMirrorKit

@Suite("Synthetic data and end-to-end metrics")
struct SyntheticDataTests {
    @Test("the same seed always produces the same stream")
    func generationIsDeterministic() {
        var a = SyntheticKeystrokeGenerator(profile: .steady, seed: 42)
        var b = SyntheticKeystrokeGenerator(profile: .steady, seed: 42)
        #expect(a.generate(count: 500) == b.generate(count: 500))
    }

    @Test("different seeds produce different streams")
    func seedsDiverge() {
        var a = SyntheticKeystrokeGenerator(profile: .steady, seed: 1)
        var b = SyntheticKeystrokeGenerator(profile: .steady, seed: 2)
        #expect(a.generate(count: 500) != b.generate(count: 500))
    }

    @Test("a steady profile classifies as steadier than a bursty one")
    func profilesClassifyAsIntended() {
        var steadyGen = SyntheticKeystrokeGenerator(profile: .steady, seed: 7)
        var burstyGen = SyntheticKeystrokeGenerator(profile: .bursty, seed: 7)

        let steady = SessionMetricsBuilder.build(events: steadyGen.generate(count: 2_000))
        let bursty = SessionMetricsBuilder.build(events: burstyGen.generate(count: 2_000))

        #expect(steady.statistics.robustCV < bursty.statistics.robustCV)
        #expect(steady.burstFraction < bursty.burstFraction)
    }

    @Test("each profile earns its namesake label")
    func profilesEarnTheirLabel() {
        let cases: [(SyntheticKeystrokeGenerator.Profile, PersonalityLabel)] = [
            (.steady, .steady),
            (.bursty, .burstHeavy),
            (.careful, .careful),
            (.editHeavy, .rapidEditing),
        ]
        for (profile, expected) in cases {
            var gen = SyntheticKeystrokeGenerator(profile: profile, seed: 7)
            let metrics = SessionMetricsBuilder.build(events: gen.generate(count: 2_000))
            #expect(metrics.labels.contains(expected))
        }
    }

    @Test("synthetic sessions land in a plausible human speed range")
    func speedsAreRealistic() {
        for profile in [SyntheticKeystrokeGenerator.Profile.steady, .bursty, .careful, .editHeavy] {
            var gen = SyntheticKeystrokeGenerator(profile: profile, seed: 7)
            let metrics = SessionMetricsBuilder.build(events: gen.generate(count: 2_000))
            #expect(metrics.grossWPM > 15)
            #expect(metrics.grossWPM < 120)
        }
    }

    @Test("an edit-heavy profile produces a higher correction rate")
    func editHeavyCorrects() {
        var careful = SyntheticKeystrokeGenerator(profile: .careful, seed: 11)
        var heavy = SyntheticKeystrokeGenerator(profile: .editHeavy, seed: 11)

        let a = SessionMetricsBuilder.build(events: careful.generate(count: 2_000))
        let b = SessionMetricsBuilder.build(events: heavy.generate(count: 2_000))

        #expect(b.correctionRate > a.correctionRate)
    }

    @Test("rhythm is always the fixed bucket count, whatever the session length")
    func rhythmLengthIsConstant() {
        for count in [80, 500, 20_000] {
            var gen = SyntheticKeystrokeGenerator(profile: .steady, seed: 3)
            let metrics = SessionMetricsBuilder.build(events: gen.generate(count: count))
            #expect(metrics.rhythm.count == SessionMetricsBuilder.rhythmBuckets)
        }
    }

    @Test("rhythm values stay normalised")
    func rhythmIsNormalised() {
        var gen = SyntheticKeystrokeGenerator(profile: .bursty, seed: 5)
        let metrics = SessionMetricsBuilder.build(events: gen.generate(count: 3_000))
        #expect(metrics.rhythm.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    @Test("effective speed never exceeds gross speed")
    func effectiveIsNeverFaster() {
        for seed in UInt64(1)...6 {
            var gen = SyntheticKeystrokeGenerator(profile: .editHeavy, seed: seed)
            let metrics = SessionMetricsBuilder.build(events: gen.generate(count: 1_500))
            #expect(metrics.effectiveWPM <= metrics.grossWPM)
        }
    }

    @Test("an empty stream produces zeroed metrics rather than trapping")
    func emptyStreamIsSafe() {
        let metrics = SessionMetricsBuilder.build(events: [])
        #expect(metrics.keystrokeCount == 0)
        #expect(metrics.grossWPM == 0)
        #expect(metrics.labels.isEmpty)
    }
}

@Suite("Peak speed and rhythm shape")
struct PeakAndRhythmTests {
    @Test("peak window speed is at least the session average")
    func peakIsAtLeastAverage() {
        for profile in [SyntheticKeystrokeGenerator.Profile.steady, .bursty, .careful, .editHeavy] {
            var gen = SyntheticKeystrokeGenerator(profile: profile, seed: 9)
            let events = gen.generate(count: 3_000)
            let metrics = SessionMetricsBuilder.build(events: events)
            #expect(metrics.peakBurstWPM >= metrics.grossWPM)
        }
    }

    @Test("peak speed stays within human range")
    func peakIsHuman() {
        for profile in [SyntheticKeystrokeGenerator.Profile.steady, .bursty, .editHeavy] {
            var gen = SyntheticKeystrokeGenerator(profile: profile, seed: 9)
            let metrics = SessionMetricsBuilder.build(events: gen.generate(count: 3_000))
            // A run of freak-fast intervals once pushed this past 250.
            #expect(metrics.peakBurstWPM < 160)
        }
    }

    @Test("a stream too short to fill the window reports no peak")
    func shortStreamHasNoPeak() {
        var gen = SyntheticKeystrokeGenerator(profile: .steady, seed: 9)
        #expect(WPMCalculator.peakWindow(events: gen.generate(count: 10)) == 0)
    }

    @Test("a window may not span an idle gap")
    func windowDoesNotSpanIdle() {
        // Fast typing, a two-minute break, then fast typing again. Neither side
        // alone fills the ten-second window, so there is no valid peak.
        let fast = (0..<40).map { _ in TypingEvent(intervalMs: 100, keyClass: .letter) }
        let events = fast + [TypingEvent(intervalMs: 120_000, keyClass: .letter)] + fast
        #expect(WPMCalculator.peakWindow(events: events) == 0)
    }

    @Test("an erratic session produces a more varied rhythm than an even one")
    func rhythmReflectsVariability() {
        var steadyGen = SyntheticKeystrokeGenerator(profile: .steady, seed: 4)
        var burstyGen = SyntheticKeystrokeGenerator(profile: .bursty, seed: 4)

        func spread(_ values: [Double]) -> Double {
            let mean = values.reduce(0, +) / Double(values.count)
            return values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        }

        let steady = SessionMetricsBuilder.build(events: steadyGen.generate(count: 3_000))
        let bursty = SessionMetricsBuilder.build(events: burstyGen.generate(count: 3_000))
        #expect(spread(bursty.rhythm) > spread(steady.rhythm))
    }

    @Test("the rhythm trace actually uses its range rather than hugging the floor")
    func rhythmFillsTheGraph() {
        // Regression guard: pooling raw intervals reported each window's slowest
        // keystroke, which flattened every bar to the bottom of the graph.
        var gen = SyntheticKeystrokeGenerator(profile: .bursty, seed: 4)
        let metrics = SessionMetricsBuilder.build(events: gen.generate(count: 3_000))
        let mean = metrics.rhythm.reduce(0, +) / Double(metrics.rhythm.count)
        #expect(mean > 0.35)
        #expect(metrics.rhythm.max() ?? 0 > 0.9)
    }
}

@Suite("Daily fingerprint")
struct FingerprintTests {
    static func summary(seed: UInt64 = 1) -> DailySummary {
        DailySummaryBuilder.build(sessions: SampleData.sessions())[0]
    }

    @Test("the same day always produces the same seed")
    func seedIsStable() {
        let a = FingerprintVector(summary: Self.summary())
        let b = FingerprintVector(summary: Self.summary())
        #expect(a.seed == b.seed)
        #expect(a == b)
    }

    @Test("quantisation absorbs floating point noise")
    func quantisationIsStable() {
        // Regression guard: hashing raw Doubles reseeded the generator on every
        // recomputation, so a day redrew differently each time it was opened.
        let base = Self.summary()
        let nudged = DailySummary(
            id: base.id,
            date: base.date,
            sessionCount: base.sessionCount,
            totalKeystrokes: base.totalKeystrokes,
            totalActiveMs: base.totalActiveMs + 0.0001,
            medianIntervalMs: base.medianIntervalMs + 0.0001,
            robustCV: base.robustCV + 0.000001,
            burstFraction: base.burstFraction + 0.000001,
            correctionRate: base.correctionRate + 0.000001,
            pauseRatePerMinute: base.pauseRatePerMinute + 0.000001,
            peakHour: base.peakHour,
            distinctCategories: base.distinctCategories,
            hourlyShare: base.hourlyShare
        )
        #expect(FingerprintVector(summary: base).seed == FingerprintVector(summary: nudged).seed)
    }

    @Test("visual parameters stay within drawable bounds")
    func parametersAreBounded() {
        for summary in DailySummaryBuilder.build(sessions: SampleData.sessions()) {
            let p = FingerprintParameters(vector: FingerprintVector(summary: summary))
            #expect(p.petalCount >= 5 && p.petalCount <= 24)
            #expect(p.radiusFraction > 0 && p.radiusFraction <= 1)
            #expect(p.brightness > 0 && p.brightness <= 1)
            #expect(p.coreFraction >= 0 && p.coreFraction < 0.3)
            #expect(p.coreSides >= 3)
            #expect(p.hourlyShare.count == 24)
        }
    }

    @Test("a faster day draws brighter than a slower one")
    func brightnessTracksSpeed() {
        // Semantic channels must be monotonic in their feature, or the image
        // carries no meaning.
        func parameters(medianMs: Double) -> FingerprintParameters {
            let base = Self.summary()
            let summary = DailySummary(
                id: base.id, date: base.date, sessionCount: base.sessionCount,
                totalKeystrokes: base.totalKeystrokes, totalActiveMs: base.totalActiveMs,
                medianIntervalMs: medianMs, robustCV: base.robustCV,
                burstFraction: base.burstFraction, correctionRate: base.correctionRate,
                pauseRatePerMinute: base.pauseRatePerMinute, peakHour: base.peakHour,
                distinctCategories: base.distinctCategories, hourlyShare: base.hourlyShare
            )
            return FingerprintParameters(vector: FingerprintVector(summary: summary))
        }
        #expect(parameters(medianMs: 120).brightness > parameters(medianMs: 400).brightness)
    }
}

@Suite("Daily aggregation")
struct DailySummaryTests {
    @Test("sessions group into days")
    func groupsByDay() {
        let summaries = DailySummaryBuilder.build(sessions: SampleData.sessions())
        #expect(!summaries.isEmpty)
        #expect(summaries.reduce(0) { $0 + $1.sessionCount } == SampleData.sessions().count)
    }

    @Test("days are returned newest first")
    func sortedNewestFirst() {
        let keys = DailySummaryBuilder.build(sessions: SampleData.sessions()).map(\.dayKey)
        #expect(keys == keys.sorted(by: >))
    }

    @Test("hourly share sums to one for any day with typing")
    func hourlyShareIsNormalised() {
        for summary in DailySummaryBuilder.build(sessions: SampleData.sessions()) {
            #expect(abs(summary.hourlyShare.reduce(0, +) - 1) < 0.0001)
        }
    }
}
