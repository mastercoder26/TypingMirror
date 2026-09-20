import Foundation

/// Converts mach tick timestamps to milliseconds.
///
/// `CGEvent.timestamp` is in `mach_absolute_time` units, not seconds. The ratio is
/// cached so the division stays off the capture hot path.
struct TimebaseConverter: Sendable {
    private let nanosecondsPerTick: Double

    init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        nanosecondsPerTick = info.denom > 0
            ? Double(info.numer) / Double(info.denom)
            : 1
    }

    func milliseconds(fromTicks ticks: UInt64) -> Double {
        Double(ticks) * nanosecondsPerTick / 1_000_000
    }
}
