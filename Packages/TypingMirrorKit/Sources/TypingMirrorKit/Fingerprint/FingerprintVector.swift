import CryptoKit
import Foundation

/// The frozen description of a day's typing style.
///
/// Features are quantised *before* hashing: without that, floating-point noise
/// would reseed the generator on every recomputation and the same day would draw
/// differently each time it was opened.
public struct FingerprintVector: Sendable, Equatable {
    public let pace: Int16
    public let variability: Int16
    public let burstiness: Int16
    public let corrections: Int16
    public let stalling: Int16
    public let volume: Int16
    public let peakHour: Int16
    public let categories: Int16
    public let hourlyShare: [Double]

    public init(summary: DailySummary) {
        func clamp(_ value: Double, _ low: Int, _ high: Int) -> Int16 {
            Int16(min(Double(high), max(Double(low), value.rounded())))
        }
        pace = clamp(summary.medianIntervalMs / 10, 5, 60)
        variability = clamp(summary.robustCV * 20, 0, 40)
        burstiness = clamp(summary.burstFraction * 40, 0, 20)
        corrections = clamp(summary.correctionRate * 100, 0, 25)
        stalling = clamp(summary.pauseRatePerMinute * 2, 0, 20)
        volume = clamp(log2(Double(max(1, summary.totalKeystrokes))), 0, 22)
        peakHour = Int16(summary.peakHour)
        categories = Int16(summary.distinctCategories)
        hourlyShare = summary.hourlyShare
    }

    /// Version tag. Changing the visual mapping means bumping this and keeping the
    /// old renderer, so a user's past fingerprints never silently change.
    static let version = "TMFPv1"

    /// Stable seed derived from the quantised features.
    public var seed: UInt64 {
        var hasher = SHA256()
        hasher.update(data: Data(Self.version.utf8))
        for value in [pace, variability, burstiness, corrections, stalling, volume, peakHour, categories] {
            withUnsafeBytes(of: value.littleEndian) { hasher.update(data: Data($0)) }
        }
        return hasher.finalize().withUnsafeBytes { $0.load(as: UInt64.self) }
    }
}

/// Visual parameters derived from a fingerprint.
///
/// Every channel here is a direct, monotonic function of a feature. The seeded
/// generator drives only non-semantic jitter — if the shape itself came from the
/// hash, two similar days would look unrelated and the image would mean nothing.
public struct FingerprintParameters: Sendable {
    public let petalCount: Int
    public let radiusFraction: Double
    public let wobble: Double
    public let strokeWidth: Double
    public let brightness: Double
    public let coreFraction: Double
    public let coreSides: Int
    public let notchCount: Int
    public let hourlyShare: [Double]
    public let seed: UInt64

    public init(vector: FingerprintVector) {
        func ramp(_ value: Double, _ low: Double, _ high: Double) -> Double {
            min(1, max(0, (value - low) / (high - low)))
        }

        let burstiness = ramp(Double(vector.burstiness), 0, 20)
        let stalling = ramp(Double(vector.stalling), 0, 20)
        let variability = ramp(Double(vector.variability), 0, 40)
        // Low pace value means short intervals, so invert it into "speed".
        let speed = 1 - ramp(Double(vector.pace), 8, 45)

        petalCount = 5 + Int((burstiness * 8).rounded()) + Int((stalling * 4).rounded())
        radiusFraction = 0.45 + 0.55 * ramp(Double(vector.volume), 7, 16)
        wobble = variability * 7
        strokeWidth = 0.7 + speed * 2.0
        brightness = 0.30 + speed * 0.65
        coreFraction = (1 - ramp(Double(vector.corrections), 2, 18)) * 0.26
        coreSides = 3 + Int(vector.categories)
        notchCount = Int(vector.corrections)
        hourlyShare = vector.hourlyShare
        seed = vector.seed
    }
}
