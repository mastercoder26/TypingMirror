import Foundation

public enum ChunkError: Error, Equatable {
    case truncated
    case badMagic
    case unsupportedVersion(UInt16)
    case checksumMismatch
    case decompressionFailed
}

/// On-disk keystroke format.
/// The uncompressed header can be read without inflating the payload. Separate
/// columns let repetitive key classes and word positions compress efficiently.
enum ChunkFormat {
    static let magic: [UInt8] = Array("TMK1".utf8)
    static let version: UInt16 = 1
    static let headerSize = 32

    enum Column: UInt8 {
        case interval = 1
        case keyClass = 2
        case wordPosition = 3
    }

    /// Intervals are stored as milliseconds in a `UInt16`, with this value
    /// escaping to a full `UInt32` for the rare longer gap.
    static let intervalEscape: UInt16 = 0xFFFF
}
