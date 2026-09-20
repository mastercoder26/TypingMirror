import Foundation

public struct PersonalityFeatures: Sendable, Equatable {
    public let robustCV: Double
    public let burstFraction: Double
    public let pauseRatePerMinute: Double
    public let correctionRate: Double
    public let correctionRunFraction: Double
    public let medianIntervalMs: Double

    public init(
        robustCV: Double,
        burstFraction: Double,
        pauseRatePerMinute: Double,
        correctionRate: Double,
        correctionRunFraction: Double,
        medianIntervalMs: Double
    ) {
        self.robustCV = robustCV
        self.burstFraction = burstFraction
        self.pauseRatePerMinute = pauseRatePerMinute
        self.correctionRate = correctionRate
        self.correctionRunFraction = correctionRunFraction
        self.medianIntervalMs = medianIntervalMs
    }
}
