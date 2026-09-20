import Foundation

/// Plain value view of a stored session, so the UI never holds a managed object.
public struct SessionRecord: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let startedAt: Date
    public let category: SessionCategory
    public let appName: String?
    public let source: CaptureSource
    public let metrics: SessionMetrics
    public let hasReplay: Bool

    public init(
        id: UUID,
        startedAt: Date,
        category: SessionCategory,
        appName: String?,
        source: CaptureSource,
        metrics: SessionMetrics,
        hasReplay: Bool
    ) {
        self.id = id
        self.startedAt = startedAt
        self.category = category
        self.appName = appName
        self.source = source
        self.metrics = metrics
        self.hasReplay = hasReplay
    }
}

extension StoredSession {
    /// Rebuilds the value view from denormalised columns, without decoding the blob.
    var record: SessionRecord {
        let statistics = IKIStatistics(
            median: medianIntervalMs,
            medianAbsoluteDeviation: 0,
            p10: 0,
            p75: p75IntervalMs,
            p90: 0,
            count: keystrokeCount,
            precomputedRobustCV: robustCV
        )
        let features = PersonalityFeatures(
            robustCV: robustCV,
            burstFraction: burstFraction,
            pauseRatePerMinute: activeMs > 0 ? Double(pauseCount) / (activeMs / 60_000) : 0,
            correctionRate: correctionRate,
            correctionRunFraction: correctionRunFraction,
            medianIntervalMs: medianIntervalMs
        )
        return SessionRecord(
            id: id,
            startedAt: startedAt,
            category: SessionCategory(rawValue: categoryRaw) ?? .mixed,
            appName: appName,
            source: CaptureSource(rawValue: sourceRaw) ?? .practicePad,
            metrics: SessionMetrics(
                keystrokeCount: keystrokeCount,
                characterCount: characterCount,
                correctionCount: correctionCount,
                activeMs: activeMs,
                wallMs: wallMs,
                grossWPM: grossWPM,
                effectiveWPM: effectiveWPM,
                peakBurstWPM: peakBurstWPM,
                longestPauseMs: longestPauseMs,
                pauseCount: pauseCount,
                statistics: statistics,
                burstFraction: burstFraction,
                correctionRate: correctionRate,
                correctionRunFraction: correctionRunFraction,
                features: features,
                labels: labelsRaw.compactMap(PersonalityLabel.init(rawValue:)),
                rhythm: rhythm
            ),
            hasReplay: eventBlob != nil
        )
    }

    func apply(
        metrics: SessionMetrics,
        startedAt: Date,
        category: SessionCategory,
        appName: String?,
        source: CaptureSource,
        calendar: Calendar = .current
    ) {
        self.startedAt = startedAt
        self.endedAt = startedAt.addingTimeInterval(metrics.wallMs / 1000)
        self.dayKey = DailySummaryBuilder.dayKey(for: startedAt, calendar: calendar)
        self.categoryRaw = category.rawValue
        self.appName = appName
        self.sourceRaw = source.rawValue
        self.keystrokeCount = metrics.keystrokeCount
        self.characterCount = metrics.characterCount
        self.correctionCount = metrics.correctionCount
        self.activeMs = metrics.activeMs
        self.wallMs = metrics.wallMs
        self.grossWPM = metrics.grossWPM
        self.effectiveWPM = metrics.effectiveWPM
        self.peakBurstWPM = metrics.peakBurstWPM
        self.longestPauseMs = metrics.longestPauseMs
        self.pauseCount = metrics.pauseCount
        self.medianIntervalMs = metrics.statistics.median
        self.robustCV = metrics.statistics.robustCV
        self.p75IntervalMs = metrics.statistics.p75
        self.burstFraction = metrics.burstFraction
        self.correctionRate = metrics.correctionRate
        self.correctionRunFraction = metrics.correctionRunFraction
        self.labelsRaw = metrics.labels.map(\.rawValue)
        self.rhythm = metrics.rhythm
    }
}
