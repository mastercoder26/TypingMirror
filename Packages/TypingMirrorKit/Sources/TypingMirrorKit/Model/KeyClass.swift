import Foundation

/// What kind of key was pressed — deliberately *not* which key.
///
/// The capture layer resolves a keycode to one of these values and discards the
/// keycode itself, so the stored stream carries no character identity.
public enum KeyClass: UInt8, Sendable, CaseIterable {
    case letter = 0
    case digit = 1
    case space = 2
    case punctuation = 3
    case backspace = 4
    case forwardDelete = 5
    case returnEnter = 6
    case tab = 7
    case navigation = 8
    case modifierChange = 9
    case shortcut = 10
    case functionKey = 11
    case escape = 12
    case imeOrNonLatin = 13
    case unknown = 14

    /// Injected by the consumer, never the capture callback, to mark a span where
    /// capture was suspended. It keeps the timeline honest instead of silently
    /// joining two unrelated stretches of typing.
    case gapSentinel = 15

    /// Whether this keystroke produced a visible character.
    public var producesCharacter: Bool {
        switch self {
        case .letter, .digit, .space, .punctuation, .returnEnter: true
        default: false
        }
    }

    public var isCorrection: Bool {
        self == .backspace || self == .forwardDelete
    }
}
