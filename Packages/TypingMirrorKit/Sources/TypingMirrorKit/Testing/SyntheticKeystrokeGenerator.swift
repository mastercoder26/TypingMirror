import Foundation

/// Generates realistic keystroke streams so metrics can be verified — and sample
/// screens populated — without anyone having to type.
public struct SyntheticKeystrokeGenerator {
    public struct Profile: Sendable {
        public let medianIntervalMs: Double
        /// Spread of the log-normal interval distribution. Higher is more erratic.
        public let sigma: Double
        public let burstProbability: Double
        public let pauseProbability: Double
        public let correctionProbability: Double

        public init(
            medianIntervalMs: Double,
            sigma: Double,
            burstProbability: Double,
            pauseProbability: Double,
            correctionProbability: Double
        ) {
            self.medianIntervalMs = medianIntervalMs
            self.sigma = sigma
            self.burstProbability = burstProbability
            self.pauseProbability = pauseProbability
            self.correctionProbability = correctionProbability
        }

        /// Even rhythm, few corrections, almost no stalling.
        public static let steady = Profile(
            medianIntervalMs: 190, sigma: 0.26,
            burstProbability: 0.006, pauseProbability: 0.0012, correctionProbability: 0.02
        )
        /// Sprints separated by thinking. Bursts stay a minority of keystrokes, so
        /// the cruising pace remains the typist's real baseline.
        public static let bursty = Profile(
            medianIntervalMs: 240, sigma: 0.58,
            burstProbability: 0.075, pauseProbability: 0.010, correctionProbability: 0.05
        )
        /// Slow, deliberate, rarely needs to fix anything.
        public static let careful = Profile(
            medianIntervalMs: 350, sigma: 0.38,
            burstProbability: 0.004, pauseProbability: 0.011, correctionProbability: 0.012
        )
        /// Types quickly and rewrites constantly.
        public static let editHeavy = Profile(
            medianIntervalMs: 180, sigma: 0.48,
            burstProbability: 0.020, pauseProbability: 0.004, correctionProbability: 0.15
        )
    }

    private let profile: Profile
    private var rng: SplitMix64

    public init(profile: Profile, seed: UInt64) {
        self.profile = profile
        self.rng = SplitMix64(seed: seed)
    }

    public mutating func generate(count: Int) -> [TypingEvent] {
        var events: [TypingEvent] = []
        events.reserveCapacity(count)
        var wordPosition: UInt8 = 0
        var burstRemaining = 0

        for index in 0..<count {
            var interval = index == 0
                ? 0
                : rng.logNormal(median: profile.medianIntervalMs, sigma: profile.sigma)

            if burstRemaining > 0 {
                interval *= 0.45
                burstRemaining -= 1
            } else if unit() < profile.burstProbability {
                burstRemaining = Int(unit() * 9) + 5
            }

            if unit() < profile.pauseProbability {
                interval += 2_200 + unit() * 11_000
            }

            let keyClass: KeyClass
            if index > 0 && unit() < profile.correctionProbability {
                keyClass = .backspace
                wordPosition = wordPosition > 0 ? wordPosition - 1 : 0
            } else if wordPosition >= 4 && unit() < 0.32 {
                keyClass = .space
                wordPosition = 0
            } else {
                keyClass = .letter
                wordPosition = min(wordPosition + 1, 255)
            }

            events.append(
                TypingEvent(intervalMs: interval, keyClass: keyClass, wordPosition: wordPosition)
            )
        }
        return events
    }

    private mutating func unit() -> Double {
        Double(rng.next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}
