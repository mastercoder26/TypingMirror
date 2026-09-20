import Foundation

/// Fixed-capacity ring of inter-keystroke intervals for live display.
///
/// Deliberately not observable: recording a keystroke must not invalidate any
/// SwiftUI view. The graph reads it on the display's own schedule instead.
public final class RhythmBuffer: @unchecked Sendable {
    private var storage: [Double]
    private var head = 0
    private(set) var count = 0
    private var lastMs: Double?
    private let lock = NSLock()

    public init(capacity: Int = 4096) {
        storage = Array(repeating: 0, count: capacity)
    }

    public func record(atMs ms: Double) {
        lock.lock(); defer { lock.unlock() }
        defer { lastMs = ms }
        guard let last = lastMs else { return }
        storage[head] = max(0, ms - last)
        head = (head + 1) % storage.count
        count = min(count + 1, storage.count)
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        head = 0
        count = 0
        lastMs = nil
    }

    public func recent(window: Int) -> [Double] {
        lock.lock(); defer { lock.unlock() }
        let available = min(count, window, storage.count)
        guard available > 0 else { return [] }
        return (0..<available).map { offset in
            storage[(head - available + offset + storage.count * 2) % storage.count]
        }
    }

    /// Normalised speed per bucket, so a pause reads as a dip rather than
    /// erasing the rhythm around it.
    public func speedSamples(buckets: Int, window: Int = 480) -> [Double] {
        let intervals = recent(window: window)
        guard intervals.count > 1, buckets > 0 else { return [] }

        let perBucket = Double(intervals.count) / Double(buckets)
        var speeds: [Double] = []
        speeds.reserveCapacity(buckets)

        for bucket in 0..<buckets {
            let low = Int(Double(bucket) * perBucket)
            let high = max(low + 1, Int(Double(bucket + 1) * perBucket))
            let slice = intervals[low..<min(high, intervals.count)]
            let elapsed = slice.reduce(0, +)
            speeds.append(elapsed > 0 ? Double(slice.count) / elapsed * 12_000 : 0)
        }

        let ceiling = speeds.max() ?? 0
        guard ceiling > 0 else { return [] }
        return speeds.map { min(1, $0 / ceiling) }
    }
}
