import Foundation

/// A session prepared for playback.
///
/// Everything is decoded and resampled once, up front. Sessions are capped at
/// forty-five minutes so the whole track fits comfortably in memory, and paying
/// that cost at load time makes scrubbing an array lookup instead of a
/// re-simulation — which is what keeps the trace correct at any playhead.
public struct ReplayTrack: Sendable {
    public let cumulativeMs: [Double]
    public let durationMs: Int
    private let speeds: [Double]

    public static let sampleCount = 600

    public init(events: [TypingEvent], compressPauses: Bool) {
        var running = 0.0
        var cumulative: [Double] = []
        cumulative.reserveCapacity(events.count)

        for event in events {
            // Clamping every gap makes a long session watchable in a couple of
            // minutes while preserving the relative shape of the rhythm.
            let interval = compressPauses ? min(event.intervalMs, 800) : event.intervalMs
            running += interval
            cumulative.append(running)
        }

        cumulativeMs = cumulative
        durationMs = Int(running)

        var samples = [Double](repeating: 0, count: Self.sampleCount)
        if running > 0, events.count > 1 {
            var counts = [Double](repeating: 0, count: Self.sampleCount)
            for (index, time) in cumulative.enumerated() where events[index].keyClass.producesCharacter {
                let bucket = min(Int(time / running * Double(Self.sampleCount)), Self.sampleCount - 1)
                counts[bucket] += 1
            }
            let peak = counts.max() ?? 1
            samples = peak > 0 ? counts.map { $0 / peak } : counts
        }
        speeds = samples
    }

    /// Resamples the precomputed trace to however many bars the view can draw.
    public func samples(buckets: Int) -> [Double] {
        guard buckets > 0, !speeds.isEmpty else { return [] }
        let perBucket = Double(speeds.count) / Double(buckets)
        return (0..<buckets).map { bucket in
            let low = Int(Double(bucket) * perBucket)
            let high = max(low + 1, Int(Double(bucket + 1) * perBucket))
            let slice = speeds[low..<min(high, speeds.count)]
            return slice.max() ?? 0
        }
    }
}

/// Playback position derived from a clock.
///
/// Holding an anchor plus a rate, rather than a mutable cursor, means seeking and
/// rate changes cannot desynchronise from what is drawn.
public struct PlaybackClock: Sendable {
    public private(set) var rate: Double = 0
    private var anchorHost: TimeInterval = 0
    private var anchorMedia: Double = 0

    public init() {}

    public func mediaMs(atHost host: TimeInterval) -> Double {
        anchorMedia + (host - anchorHost) * 1000 * rate
    }

    public mutating func seek(toMs ms: Double, host: TimeInterval) {
        anchorMedia = ms
        anchorHost = host
    }

    public mutating func setRate(_ newRate: Double, host: TimeInterval) {
        anchorMedia = mediaMs(atHost: host)
        anchorHost = host
        rate = newRate
    }
}
