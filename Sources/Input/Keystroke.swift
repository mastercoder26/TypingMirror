import Foundation

/// A single keystroke as the app sees it.
public struct Keystroke: Sendable {
    public enum Kind: Sendable {
        case text(Character)
        case backspace
        case wordDelete
    }

    public let kind: Kind
    /// Seconds since boot, taken from `NSEvent.timestamp`.
    ///
    /// This is stamped when the event was created, not when we were scheduled to
    /// handle it, so it measures the user's typing rather than our own dispatch
    /// latency.
    public let timestamp: TimeInterval
    public let isRepeat: Bool

    public init(kind: Kind, timestamp: TimeInterval, isRepeat: Bool = false) {
        self.kind = kind
        self.timestamp = timestamp
        self.isRepeat = isRepeat
    }
}
