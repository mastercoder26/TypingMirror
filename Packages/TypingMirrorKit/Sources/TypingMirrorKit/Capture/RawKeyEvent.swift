import Foundation

/// What crosses the boundary out of the event-tap callback.
///
/// Note what is absent: there is no keycode and no character. The keycode is
/// resolved to a class inside the callback and discarded there, so character
/// identity never outlives a single stack frame. That is a property of the data
/// structure rather than a policy that could be toggled off.
struct RawKeyEvent: Sendable {
    var timestampTicks: UInt64 = 0
    var keyClass: UInt8 = 0
    var isRepeat: Bool = false
}

/// Single-producer, single-consumer ring buffer.
///
/// The tap thread is the only producer and one task is the only consumer, so the
/// indices need no lock — which matters because the callback must not block.
final class KeyEventRingBuffer: @unchecked Sendable {
    private var storage: [RawKeyEvent]
    private let mask: Int
    private let lock = NSLock()
    private var writeIndex = 0
    private var readIndex = 0
    private(set) var droppedCount = 0

    /// Capacity is rounded to a power of two so indexing is a mask, not a modulo.
    init(capacityPowerOfTwo: Int = 16) {
        let capacity = 1 << capacityPowerOfTwo
        storage = Array(repeating: RawKeyEvent(), count: capacity)
        mask = capacity - 1
    }

    /// Returns false when the buffer is full, in which case the event is dropped
    /// and counted rather than silently lost.
    @discardableResult
    func tryPush(_ event: RawKeyEvent) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard writeIndex - readIndex < storage.count else {
            droppedCount += 1
            return false
        }
        storage[writeIndex & mask] = event
        writeIndex += 1
        return true
    }

    func drain() -> [RawKeyEvent] {
        lock.lock()
        defer { lock.unlock() }
        guard writeIndex > readIndex else { return [] }
        let events = (readIndex..<writeIndex).map { storage[$0 & mask] }
        readIndex = writeIndex
        return events
    }
}
