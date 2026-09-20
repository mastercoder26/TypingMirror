import Foundation

/// Assigns typing-style labels using fixed rules.
/// The same features give the same labels without a training dataset.
public enum PersonalityClassifier {
    static let applyThreshold = 0.55
    static let maximumLabels = 2

    /// Piecewise-linear ramp mapping a raw feature onto 0...1.
    @inline(__always)
    static func ramp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        guard high > low else { return 0 }
        return min(1, max(0, (value - low) / (high - low)))
    }

    /// Weighted contributions per label, kept as data so that the explanation text
    /// and the score can never drift apart.
    static func contributions(_ features: PersonalityFeatures) -> [PersonalityLabel: [(reason: String, weight: Double)]] {
        [
            .steady: [
                ("even rhythm", 0.45 * (1 - ramp(features.robustCV, 0.30, 0.95))),
                ("few pauses", 0.35 * (1 - ramp(features.pauseRatePerMinute, 0.30, 3.00))),
                ("few corrections", 0.20 * (1 - ramp(features.correctionRate, 0.03, 0.12))),
            ],
            .burstHeavy: [
                ("keystrokes in bursts", 0.55 * ramp(features.burstFraction, 0.03, 0.16)),
                ("variable rhythm", 0.25 * ramp(features.robustCV, 0.40, 1.00)),
                ("pauses between bursts", 0.20 * ramp(features.pauseRatePerMinute, 0.80, 4.00)),
            ],
            .careful: [
                ("few corrections", 0.40 * (1 - ramp(features.correctionRate, 0.02, 0.10))),
                ("measured pace", 0.30 * ramp(features.medianIntervalMs, 180, 420)),
                ("pauses before committing", 0.30 * ramp(features.pauseRatePerMinute, 1.00, 4.00)),
            ],
            .rapidEditing: [
                ("frequent corrections", 0.50 * ramp(features.correctionRate, 0.06, 0.20)),
                ("corrections in runs", 0.30 * ramp(features.correctionRunFraction, 0.25, 0.65)),
                ("quick pace", 0.20 * (1 - ramp(features.medianIntervalMs, 150, 400))),
            ],
        ]
    }

    public static func scores(_ features: PersonalityFeatures) -> [PersonalityLabel: Double] {
        contributions(features).mapValues { $0.reduce(0) { $0 + $1.weight } }
    }

    /// The single strongest reason a label applied, for user-facing explanation.
    public static func explanation(for label: PersonalityLabel, features: PersonalityFeatures) -> String {
        contributions(features)[label]?
            .max { $0.weight < $1.weight }?
            .reason ?? ""
    }

    /// Labels can co-apply, but contradictory pairs resolve to the stronger one.
    public static func classify(_ features: PersonalityFeatures, keystrokes: Int) -> [PersonalityLabel] {
        guard keystrokes >= 120 else { return [] }

        var ranked = scores(features)
            .filter { $0.value >= applyThreshold }
            .sorted { $0.value > $1.value }

        for (first, second) in PersonalityLabel.contradictions {
            guard let firstScore = ranked.first(where: { $0.key == first })?.value,
                  let secondScore = ranked.first(where: { $0.key == second })?.value
            else { continue }
            let weaker = firstScore >= secondScore ? second : first
            ranked.removeAll { $0.key == weaker }
        }

        return ranked.prefix(maximumLabels).map(\.key)
    }
}
