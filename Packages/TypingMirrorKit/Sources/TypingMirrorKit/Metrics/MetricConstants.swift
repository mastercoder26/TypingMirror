import Foundation

/// Every tunable threshold in one place.
///
/// These are reasoned defaults, not validated norms. They live here so that
/// recalibration against real typing data is a one-file change.
public enum MetricConstants {
    /// A "word" is five characters by the standard typing convention.
    public static let charactersPerWord = 5.0

    /// Gaps longer than this are excluded from active time. All speed figures use
    /// active time, so that staring at the screen does not read as slow typing.
    public static let idleMs = 15_000.0

    /// The reported "long pause" threshold — roughly 10x a typical interval, which
    /// puts it past linguistic planning and into deliberate thought.
    public static let pauseMs = 2_000.0

    /// Hesitation is relative to the typist's own median, with an absolute floor so
    /// that fast and slow typists both get sane results.
    public static let hesitationMedianMultiple = 3.0
    public static let hesitationFloorMs = 400.0

    /// A burst is a run of keystrokes fast *relative to this typist's cruising
    /// pace*. The baseline is the 75th percentile rather than the median: for a
    /// heavily bursty typist the bursts dominate the median and drag it down, so a
    /// median-anchored threshold collapses below the very runs it should catch.
    public static let burstIntervalFraction = 0.55
    public static let burstMinimumRun = 5

    /// Window used for the headline "fastest burst" figure. Peak speed is
    /// measured over the fastest stretch of this length rather than over a single
    /// run of keystrokes: a handful of freak-fast intervals produces speeds no
    /// human sustains, the same way a two-second split flatters a runner.
    public static let peakWindowMs = 10_000.0

    /// Continuous streams split into sessions at this gap.
    ///
    /// Deliberately short. A longer boundary is arguably more faithful to what a
    /// "session" means, but nothing is written until a session closes, so a long
    /// one makes the app look broken while you are still typing.
    public static let sessionBreakMs = 45_000.0

    /// Sessions below either floor are statistical noise and are discarded.
    ///
    /// Low enough that a real stretch of typing is kept, high enough that a
    /// stray keypress does not become a row claiming to describe your style.
    public static let minimumKeystrokes = 25
    public static let minimumActiveMs = 8_000.0

    /// Time constant for the live speed estimate. At a ~250ms interval this
    /// averages roughly the last ten keystrokes.
    public static let liveEmaTauMs = 2_500.0

    /// Scale factor converting median absolute deviation to a standard-deviation
    /// equivalent for a normal distribution.
    public static let madToSigma = 1.4826
}
