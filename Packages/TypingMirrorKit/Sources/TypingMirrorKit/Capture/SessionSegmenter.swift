import Foundation

/// Splits a continuous keystroke stream into sessions.
///
/// A pure state machine with no I/O, so every boundary rule is directly testable.
public struct SessionSegmenter: Sendable {
    public struct Segment: Sendable, Equatable {
        public let events: [TypingEvent]
        public let startedAt: Date
        public let appName: String?
        public let category: SessionCategory
    }

    /// Sessions are capped so that replay and metrics stay bounded.
    public static let maximumSessionMs = 45 * 60 * 1_000.0

    private var events: [TypingEvent] = []
    private var startedAt: Date?
    private var elapsedMs = 0.0
    private var appName: String?
    private var category: SessionCategory = .mixed

    public init() {}

    public var isEmpty: Bool { events.isEmpty }
    public var count: Int { events.count }

    /// Feeds one keystroke in, returning a finished segment when this event begins
    /// a new one.
    public mutating func accept(
        event: TypingEvent,
        at date: Date,
        appName: String?,
        category: SessionCategory
    ) -> Segment? {
        var finished: Segment?

        let breaksOnIdle = event.intervalMs > MetricConstants.sessionBreakMs
        let breaksOnLength = elapsedMs + event.intervalMs > Self.maximumSessionMs

        if !events.isEmpty, breaksOnIdle || breaksOnLength {
            finished = close()
        }

        if events.isEmpty {
            startedAt = date
            self.appName = appName
            self.category = category
            // The first event of a session has no meaningful preceding interval.
            events.append(TypingEvent(intervalMs: 0, keyClass: event.keyClass, wordPosition: event.wordPosition))
        } else {
            elapsedMs += event.intervalMs
            events.append(event)
            // Alt-tabbing mid-sentence is still one session, so a changed app only
            // makes the session mixed rather than splitting it.
            if appName != self.appName, self.category != .mixed, category != self.category {
                self.category = .mixed
                self.appName = nil
            }
        }

        return finished
    }

    public mutating func close() -> Segment? {
        defer {
            events = []
            startedAt = nil
            elapsedMs = 0
            appName = nil
            category = .mixed
        }
        guard let startedAt, !events.isEmpty else { return nil }
        return Segment(events: events, startedAt: startedAt, appName: appName, category: category)
    }
}
