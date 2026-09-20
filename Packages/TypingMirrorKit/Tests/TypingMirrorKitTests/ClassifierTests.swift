import Testing
@testable import TypingMirrorKit

@Suite("Personality classifier")
struct PersonalityClassifierTests {
    static func f(
        cv: Double = 0.5,
        burst: Double = 0.1,
        pauseRate: Double = 1.0,
        correction: Double = 0.04,
        runFraction: Double = 0.2,
        median: Double = 200
    ) -> PersonalityFeatures {
        PersonalityFeatures(
            robustCV: cv,
            burstFraction: burst,
            pauseRatePerMinute: pauseRate,
            correctionRate: correction,
            correctionRunFraction: runFraction,
            medianIntervalMs: median
        )
    }

    @Test("an even, clean session reads as steady")
    func steadySession() {
        let labels = PersonalityClassifier.classify(
            Self.f(cv: 0.20, burst: 0.05, pauseRate: 0.2, correction: 0.01),
            keystrokes: 900
        )
        #expect(labels.contains(.steady))
    }

    @Test("a bursty session reads as burst-heavy and not as steady")
    func burstySession() {
        let labels = PersonalityClassifier.classify(
            Self.f(cv: 1.20, burst: 0.44, pauseRate: 4.5, correction: 0.05),
            keystrokes: 900
        )
        #expect(labels.contains(.burstHeavy))
        #expect(!labels.contains(.steady))
    }

    @Test("a correction-heavy session reads as rapid editing")
    func editHeavySession() {
        let labels = PersonalityClassifier.classify(
            Self.f(correction: 0.19, runFraction: 0.62, median: 160),
            keystrokes: 900
        )
        #expect(labels.contains(.rapidEditing))
    }

    @Test("contradictory labels never co-apply")
    func contradictionsResolved() {
        for cv in stride(from: 0.0, through: 2.0, by: 0.1) {
            for correction in stride(from: 0.0, through: 0.3, by: 0.02) {
                let labels = PersonalityClassifier.classify(
                    Self.f(cv: cv, burst: cv / 2, correction: correction),
                    keystrokes: 900
                )
                for (a, b) in PersonalityLabel.contradictions {
                    #expect(!(labels.contains(a) && labels.contains(b)))
                }
            }
        }
    }

    @Test("at most two labels are returned")
    func labelCountIsCapped() {
        let labels = PersonalityClassifier.classify(
            Self.f(cv: 0.1, burst: 0.5, pauseRate: 0.1, correction: 0.0, median: 400),
            keystrokes: 900
        )
        #expect(labels.count <= 2)
    }

    @Test("a session too short to characterise gets no label")
    func shortSessionIsUnlabelled() {
        #expect(PersonalityClassifier.classify(Self.f(), keystrokes: 50).isEmpty)
    }

    @Test("every applied label can explain itself")
    func labelsExplainThemselves() {
        let f = Self.f(cv: 1.20, burst: 0.44, pauseRate: 4.5)
        for label in PersonalityClassifier.classify(f, keystrokes: 900) {
            #expect(!PersonalityClassifier.explanation(for: label, features: f).isEmpty)
        }
    }
}
