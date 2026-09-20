import Foundation

struct ByteWriter {
    private(set) var bytes: [UInt8] = []

    mutating func append(_ value: UInt8) { bytes.append(value) }

    mutating func append(_ value: UInt16) {
        withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
    }

    mutating func append(_ value: UInt32) {
        withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
    }

    mutating func append(_ value: Int64) {
        withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
    }

    mutating func append(contentsOf other: [UInt8]) { bytes.append(contentsOf: other) }
}

struct ByteReader {
    private let bytes: [UInt8]
    private(set) var offset = 0

    init(_ data: Data) { bytes = Array(data) }

    var remaining: Int { bytes.count - offset }

    mutating func readUInt8() throws -> UInt8 {
        guard remaining >= 1 else { throw ChunkError.truncated }
        defer { offset += 1 }
        return bytes[offset]
    }

    mutating func readUInt16() throws -> UInt16 {
        guard remaining >= 2 else { throw ChunkError.truncated }
        defer { offset += 2 }
        return UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
    }

    mutating func readUInt32() throws -> UInt32 {
        guard remaining >= 4 else { throw ChunkError.truncated }
        defer { offset += 4 }
        var value: UInt32 = 0
        for index in 0..<4 {
            value |= UInt32(bytes[offset + index]) << (8 * UInt32(index))
        }
        return value
    }

    mutating func readInt64() throws -> Int64 {
        guard remaining >= 8 else { throw ChunkError.truncated }
        defer { offset += 8 }
        var value: UInt64 = 0
        for index in 0..<8 {
            value |= UInt64(bytes[offset + index]) << (8 * UInt64(index))
        }
        return Int64(bitPattern: value)
    }

    mutating func readBytes(_ count: Int) throws -> [UInt8] {
        guard remaining >= count else { throw ChunkError.truncated }
        defer { offset += count }
        return Array(bytes[offset..<(offset + count)])
    }
}

/// CRC-32, used to detect a truncated or corrupted chunk before decoding it.
enum CRC32 {
    private static let table: [UInt32] = (0..<256).map { index -> UInt32 in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = (value & 1) == 1 ? (value >> 1) ^ 0xEDB8_8320 : value >> 1
        }
        return value
    }

    static func compute(_ bytes: [UInt8]) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in bytes {
            crc = (crc >> 8) ^ table[Int((crc ^ UInt32(byte)) & 0xFF)]
        }
        return crc ^ 0xFFFF_FFFF
    }
}
