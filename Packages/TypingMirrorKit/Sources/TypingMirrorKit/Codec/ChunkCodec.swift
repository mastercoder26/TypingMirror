import Compression
import Foundation

/// Encodes and decodes keystroke streams.
///
/// Deliberately free of any SwiftData dependency, so the format is exhaustively
/// testable on its own and can be moved to flat files later without touching the
/// persistence layer.
public enum ChunkCodec {
    public static func encode(events: [TypingEvent], startedAt: Date) throws -> Data {
        var intervals = ByteWriter()
        var classes: [UInt8] = []
        var positions: [UInt8] = []
        var totalMs = 0.0

        for event in events {
            let ms = max(0, event.intervalMs.rounded())
            totalMs += ms
            let clamped = UInt32(min(ms, Double(UInt32.max)))
            if clamped < UInt32(ChunkFormat.intervalEscape) {
                intervals.append(UInt16(clamped))
            } else {
                intervals.append(ChunkFormat.intervalEscape)
                intervals.append(clamped)
            }
            classes.append(event.keyClass.rawValue)
            positions.append(event.wordPosition)
        }

        // Two key classes fit in a byte; word positions rarely exceed a nibble's
        // worth of meaning but are kept whole for the heatmap's intra-word axis.
        var payload = ByteWriter()
        payload.append(UInt8(3))
        appendColumn(&payload, id: .interval, bytes: intervals.bytes)
        appendColumn(&payload, id: .keyClass, bytes: packNibbles(classes))
        appendColumn(&payload, id: .wordPosition, bytes: positions)

        let compressed = compress(payload.bytes)

        var out = ByteWriter()
        out.append(contentsOf: ChunkFormat.magic)
        out.append(ChunkFormat.version)
        out.append(UInt16(0))
        out.append(UInt32(events.count))
        out.append(Int64(startedAt.timeIntervalSince1970 * 1000))
        out.append(UInt32(min(totalMs, Double(UInt32.max))))
        out.append(UInt32(compressed.count))
        out.append(CRC32.compute(compressed))
        out.append(contentsOf: compressed)
        return Data(out.bytes)
    }

    public static func decode(_ data: Data) throws -> [TypingEvent] {
        var reader = ByteReader(data)
        guard try reader.readBytes(4) == ChunkFormat.magic else { throw ChunkError.badMagic }

        let version = try reader.readUInt16()
        guard version == ChunkFormat.version else {
            throw ChunkError.unsupportedVersion(version)
        }
        _ = try reader.readUInt16()
        let count = Int(try reader.readUInt32())
        _ = try reader.readInt64()
        _ = try reader.readUInt32()
        let payloadSize = Int(try reader.readUInt32())
        let checksum = try reader.readUInt32()

        let stored = try reader.readBytes(payloadSize)
        guard CRC32.compute(stored) == checksum else { throw ChunkError.checksumMismatch }

        let payload = try decompress(stored)
        var columns = ByteReader(Data(payload))
        let columnCount = try columns.readUInt8()

        var intervals: [Double] = []
        var classes: [UInt8] = []
        var positions: [UInt8] = []

        for _ in 0..<columnCount {
            let id = try columns.readUInt8()
            let length = Int(try columns.readUInt32())
            let bytes = try columns.readBytes(length)

            switch ChunkFormat.Column(rawValue: id) {
            case .interval: intervals = try decodeIntervals(bytes, count: count)
            case .keyClass: classes = unpackNibbles(bytes, count: count)
            case .wordPosition: positions = bytes
            case nil: continue
            }
        }

        guard intervals.count >= count, classes.count >= count else {
            throw ChunkError.truncated
        }

        return (0..<count).map { index in
            TypingEvent(
                intervalMs: intervals[index],
                keyClass: KeyClass(rawValue: classes[index]) ?? .unknown,
                wordPosition: index < positions.count ? positions[index] : 0
            )
        }
    }

    // MARK: Columns

    private static func appendColumn(_ writer: inout ByteWriter, id: ChunkFormat.Column, bytes: [UInt8]) {
        writer.append(id.rawValue)
        writer.append(UInt32(bytes.count))
        writer.append(contentsOf: bytes)
    }

    private static func decodeIntervals(_ bytes: [UInt8], count: Int) throws -> [Double] {
        var result: [Double] = []
        result.reserveCapacity(count)
        var index = 0
        while result.count < count {
            guard index + 2 <= bytes.count else { throw ChunkError.truncated }
            let low = UInt16(bytes[index]) | (UInt16(bytes[index + 1]) << 8)
            index += 2
            if low != ChunkFormat.intervalEscape {
                result.append(Double(low))
                continue
            }
            guard index + 4 <= bytes.count else { throw ChunkError.truncated }
            var wide: UInt32 = 0
            for offset in 0..<4 {
                wide |= UInt32(bytes[index + offset]) << (8 * UInt32(offset))
            }
            index += 4
            result.append(Double(wide))
        }
        return result
    }

    private static func packNibbles(_ values: [UInt8]) -> [UInt8] {
        var packed: [UInt8] = []
        packed.reserveCapacity((values.count + 1) / 2)
        var index = 0
        while index < values.count {
            let low = values[index] & 0x0F
            let high = index + 1 < values.count ? (values[index + 1] & 0x0F) : 0
            packed.append(low | (high << 4))
            index += 2
        }
        return packed
    }

    private static func unpackNibbles(_ bytes: [UInt8], count: Int) -> [UInt8] {
        var values: [UInt8] = []
        values.reserveCapacity(count)
        for byte in bytes {
            values.append(byte & 0x0F)
            if values.count < count { values.append((byte >> 4) & 0x0F) }
        }
        return values
    }

    // MARK: Compression

    private static func compress(_ bytes: [UInt8]) -> [UInt8] {
        guard !bytes.isEmpty else { return [] }
        let capacity = bytes.count + 1024
        var destination = [UInt8](repeating: 0, count: capacity)
        let written = bytes.withUnsafeBufferPointer { source in
            compression_encode_buffer(
                &destination, capacity, source.baseAddress!, bytes.count, nil, COMPRESSION_LZFSE
            )
        }
        // Incompressible payloads fall back to raw bytes, flagged by a leading 0.
        guard written > 0, written < bytes.count else { return [0] + bytes }
        return [1] + destination[0..<written]
    }

    private static func decompress(_ bytes: [UInt8]) throws -> [UInt8] {
        guard let flag = bytes.first else { return [] }
        let body = Array(bytes.dropFirst())
        guard flag == 1 else { return body }

        var capacity = max(1024, body.count * 8)
        for _ in 0..<6 {
            var destination = [UInt8](repeating: 0, count: capacity)
            let written = body.withUnsafeBufferPointer { source in
                compression_decode_buffer(
                    &destination, capacity, source.baseAddress!, body.count, nil, COMPRESSION_LZFSE
                )
            }
            if written > 0 && written < capacity {
                return Array(destination[0..<written])
            }
            capacity *= 4
        }
        throw ChunkError.decompressionFailed
    }
}
