import Foundation

/// Small, fast, seedable PRNG.
///
/// Determinism matters twice over: sample data must be reproducible, and the
/// daily fingerprint must render identically every time it is drawn.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Log-normally distributed value, which is how inter-keystroke intervals are
    /// actually shaped: a tight cluster with a long tail of thinking pauses.
    public mutating func logNormal(median: Double, sigma: Double) -> Double {
        var u1 = Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
        let u2 = Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
        if u1 <= 0 { u1 = 1e-12 }
        let normal = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
        return median * exp(sigma * normal)
    }
}
