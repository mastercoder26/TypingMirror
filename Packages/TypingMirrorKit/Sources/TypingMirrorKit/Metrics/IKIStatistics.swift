import Foundation

/// Robust statistics over inter-keystroke intervals.
///
/// Interval distributions are roughly log-normal with a long right tail from
/// thinking pauses, so the arithmetic mean is misleading — a single 30-second
/// pause drags it past every real keystroke. Everything here is median-based.
public struct IKIStatistics: Sendable, Equatable {
    public let median: Double
    public let medianAbsoluteDeviation: Double
    public let p10: Double
    /// The typist's relaxed cruising pace. Used as the burst baseline because,
    /// unlike the median, it is barely affected by how much of the session was
    /// spent bursting — bursts live in the left tail.
    public let p75: Double
    public let p90: Double
    public let count: Int
    private var storedRobustCV: Double?

    /// Coefficient of variation built from the MAD rather than the standard
    /// deviation. This is the app's primary "steadiness" feature.
    public var robustCV: Double {
        if let storedRobustCV { return storedRobustCV }
        guard median > 0 else { return 0 }
        return MetricConstants.madToSigma * medianAbsoluteDeviation / median
    }

    /// Rehydrates from denormalised columns, where the raw intervals are no
    /// longer available and the coefficient of variation was stored directly.
    init(
        median: Double,
        medianAbsoluteDeviation: Double,
        p10: Double,
        p75: Double,
        p90: Double,
        count: Int,
        precomputedRobustCV: Double
    ) {
        self.median = median
        self.medianAbsoluteDeviation = medianAbsoluteDeviation
        self.p10 = p10
        self.p75 = p75
        self.p90 = p90
        self.count = count
        self.storedRobustCV = precomputedRobustCV
    }

    public init(intervals: [Double]) {
        let sorted = intervals.sorted()
        count = sorted.count
        guard !sorted.isEmpty else {
            median = 0
            medianAbsoluteDeviation = 0
            p10 = 0
            p75 = 0
            p90 = 0
            storedRobustCV = nil
            return
        }
        let med = Self.quantile(sorted, 0.5)
        median = med
        p10 = Self.quantile(sorted, 0.10)
        p75 = Self.quantile(sorted, 0.75)
        p90 = Self.quantile(sorted, 0.90)
        medianAbsoluteDeviation = Self.quantile(sorted.map { abs($0 - med) }.sorted(), 0.5)
        storedRobustCV = nil
    }

    /// Linear-interpolated quantile over an already-sorted array.
    static func quantile(_ sorted: [Double], _ q: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        guard sorted.count > 1 else { return sorted[0] }
        let position = q * Double(sorted.count - 1)
        let lower = Int(position)
        let upper = min(lower + 1, sorted.count - 1)
        return sorted[lower] + (position - Double(lower)) * (sorted[upper] - sorted[lower])
    }
}
