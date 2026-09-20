import Foundation
import Testing
@testable import TypingMirrorKit

@Suite("Chunk codec")
struct ChunkCodecTests {
    static func sampleEvents(count: Int = 4_000, seed: UInt64 = 21) -> [TypingEvent] {
        var gen = SyntheticKeystrokeGenerator(profile: .bursty, seed: seed)
        return gen.generate(count: count)
    }

    @Test("a stream survives a round trip unchanged")
    func roundTripPreservesEvents() throws {
        let original = Self.sampleEvents()
        let decoded = try ChunkCodec.decode(ChunkCodec.encode(events: original, startedAt: Date()))

        #expect(decoded.count == original.count)
        for (a, b) in zip(original, decoded) {
            // Intervals are stored at millisecond resolution.
            #expect(abs(a.intervalMs.rounded() - b.intervalMs) < 1)
            #expect(a.keyClass == b.keyClass)
            #expect(a.wordPosition == b.wordPosition)
        }
    }

    @Test("metrics computed before and after a round trip agree")
    func metricsSurviveRoundTrip() throws {
        let original = Self.sampleEvents()
        let decoded = try ChunkCodec.decode(ChunkCodec.encode(events: original, startedAt: Date()))

        let before = SessionMetricsBuilder.build(events: original)
        let after = SessionMetricsBuilder.build(events: decoded)

        #expect(abs(before.grossWPM - after.grossWPM) < 0.5)
        #expect(before.correctionCount == after.correctionCount)
        #expect(before.labels == after.labels)
    }

    @Test("gaps longer than the escape threshold survive")
    func longGapsSurvive() throws {
        // A five-minute break exceeds what a UInt16 of milliseconds can hold, so
        // it must take the escape path.
        let events = [
            TypingEvent(intervalMs: 0, keyClass: .letter),
            TypingEvent(intervalMs: 300_000, keyClass: .letter),
            TypingEvent(intervalMs: 120, keyClass: .letter),
        ]
        let decoded = try ChunkCodec.decode(ChunkCodec.encode(events: events, startedAt: Date()))
        #expect(decoded[1].intervalMs == 300_000)
    }

    @Test("every key class survives the nibble packing")
    func allKeyClassesSurvive() throws {
        let events = KeyClass.allCases.map {
            TypingEvent(intervalMs: 100, keyClass: $0, wordPosition: 7)
        }
        let decoded = try ChunkCodec.decode(ChunkCodec.encode(events: events, startedAt: Date()))
        #expect(decoded.map(\.keyClass) == KeyClass.allCases)
    }

    @Test("an odd number of events packs and unpacks correctly")
    func oddCountPacksCorrectly() throws {
        let events = (0..<7).map { TypingEvent(intervalMs: Double($0 * 10), keyClass: .letter) }
        let decoded = try ChunkCodec.decode(ChunkCodec.encode(events: events, startedAt: Date()))
        #expect(decoded.count == 7)
    }

    @Test("an empty stream round trips")
    func emptyRoundTrips() throws {
        let decoded = try ChunkCodec.decode(ChunkCodec.encode(events: [], startedAt: Date()))
        #expect(decoded.isEmpty)
    }

    @Test("corrupted bytes are rejected rather than silently decoded")
    func corruptionIsDetected() throws {
        var data = try ChunkCodec.encode(events: Self.sampleEvents(count: 200), startedAt: Date())
        data[data.count - 8] ^= 0xFF
        #expect(throws: (any Error).self) { try ChunkCodec.decode(data) }
    }

    @Test("a truncated chunk is rejected")
    func truncationIsDetected() throws {
        let data = try ChunkCodec.encode(events: Self.sampleEvents(count: 200), startedAt: Date())
        #expect(throws: (any Error).self) { try ChunkCodec.decode(data.prefix(40)) }
    }

    @Test("foreign data is rejected")
    func badMagicIsDetected() {
        #expect(throws: ChunkError.badMagic) {
            try ChunkCodec.decode(Data(repeating: 9, count: 64))
        }
    }

    @Test("storage stays under two bytes per keystroke")
    func storageIsCompact() throws {
        // A year of heavy typing has to stay in single-digit megabytes.
        let events = Self.sampleEvents(count: 20_000)
        let data = try ChunkCodec.encode(events: events, startedAt: Date())
        let bytesPerEvent = Double(data.count) / Double(events.count)
        #expect(bytesPerEvent < 2.0)
    }
}
