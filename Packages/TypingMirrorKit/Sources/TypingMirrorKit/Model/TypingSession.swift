import Foundation

/// A completed session: identity, provenance, and its computed metrics.
public struct TypingSession: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let startedAt: Date
    public let category: SessionCategory
    /// The app most of the typing happened in, when it is known.
    public let appName: String?
    public let metrics: SessionMetrics

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        category: SessionCategory,
        appName: String?,
        metrics: SessionMetrics
    ) {
        self.id = id
        self.startedAt = startedAt
        self.category = category
        self.appName = appName
        self.metrics = metrics
    }

    /// Sessions are numbered for display in the order they were recorded.
    public var wallDuration: Duration {
        .milliseconds(Int(metrics.wallMs))
    }
}
