import Foundation

public enum ChunkError: Error, Equatable {
    case truncated
    case badMagic
    case unsupportedVersion(UInt16)
    case checksumMismatch
    case decompressionFailed
}

/// On-disk layout for a keystroke stream.
///
/// A fixed uncompressed header lets a chunk be identified and time-ranged without
/// inflating its payload; the payload itself is columnar so that the highly
/// repetitive key-class and word-position columns compress hard while the
/// near-incompressible interval column sits on its own.
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
