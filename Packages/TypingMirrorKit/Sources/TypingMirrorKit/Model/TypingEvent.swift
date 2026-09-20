import Foundation

/// One keystroke, reduced to timing and key class.
public struct TypingEvent: Sendable, Equatable {
    /// Milliseconds since the previous event. Zero for the first.
    public let intervalMs: Double
    public let keyClass: KeyClass
    /// Characters typed since the start of the current word. Gives the correction
    /// heatmap an intra-word axis without storing any character.
    public let wordPosition: UInt8

    public init(intervalMs: Double, keyClass: KeyClass, wordPosition: UInt8 = 0) {
        self.intervalMs = intervalMs
        self.keyClass = keyClass
        self.wordPosition = wordPosition
    }
}
