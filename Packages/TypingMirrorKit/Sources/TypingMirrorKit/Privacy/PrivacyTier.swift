import Foundation

/// What the app is permitted to retain.
public enum PrivacyTier: String, Sendable, CaseIterable, Identifiable, Codable {
    /// Timing and key class only. No character ever reaches storage.
    case rhythmOnly
    /// Adds word length and position, which still carry no identity.
    case wordShapes
    /// Adds the actual words typed. Off by default and never implied.
    case lexical

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .rhythmOnly: "Rhythm only"
        case .wordShapes: "Rhythm and word shapes"
        case .lexical: "Rhythm and words"
        }
    }

    public var summary: String {
        switch self {
        case .rhythmOnly:
            "Stores when you pressed keys and what kind of key it was. "
                + "No characters, no keycodes, nothing you typed."
        case .wordShapes:
            "Adds how long each word was and where it sat in the sentence. "
                + "Still stores nothing you could read back."
        case .lexical:
            "Adds the words themselves, so hesitation can be reported by word. "
                + "This is the only setting that stores anything you typed."
        }
    }

    public var storesText: Bool { self == .lexical }
}
