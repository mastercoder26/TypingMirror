import Foundation
import SwiftData

/// A persisted session.
///
/// Metrics are denormalised onto the row so that lists and charts never have to
/// decode the keystroke blob; the blob is touched only by replay.
@Model
public final class StoredSession {
    #Index<StoredSession>([\.startedAt], [\.dayKey])

    public var id: UUID = UUID()
    public var startedAt: Date = Date.distantPast
    public var endedAt: Date = Date.distantPast
    public var dayKey: Int = 0
    public var categoryRaw: String = SessionCategory.mixed.rawValue
    public var appName: String?
    public var sourceRaw: String = CaptureSource.practicePad.rawValue

    public var keystrokeCount: Int = 0
    public var characterCount: Int = 0
    public var correctionCount: Int = 0
    public var activeMs: Double = 0
    public var wallMs: Double = 0
    public var grossWPM: Double = 0
    public var effectiveWPM: Double = 0
    public var peakBurstWPM: Double = 0
    public var longestPauseMs: Double = 0
    public var pauseCount: Int = 0
    public var medianIntervalMs: Double = 0
    public var robustCV: Double = 0
    public var p75IntervalMs: Double = 0
    public var burstFraction: Double = 0
    public var correctionRate: Double = 0
    public var correctionRunFraction: Double = 0
    public var labelsRaw: [String] = []
    public var rhythm: [Double] = []

    /// Present only when the session is long enough to be worth replaying.
    @Attribute(.externalStorage) public var eventBlob: Data?

    public init() {}
}

/// A word the user hesitated on, stored only under the opt-in lexical tier.
@Model
public final class StoredWord {
    public var text: String = ""
    public var capturedAt: Date = Date.distantPast
    public var hesitationMs: Double = 0
    public var isFromTest: Bool = false

    public init() {}
}

public enum CaptureSource: String, Sendable, Codable {
    case practicePad
    case typingTest
    case global
}
