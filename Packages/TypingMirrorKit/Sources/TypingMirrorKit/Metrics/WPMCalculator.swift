import Foundation

public enum WPMCalculator {
    /// Time spent actually typing, excluding idle gaps.
    ///
    /// Every speed figure in the app is built on this rather than wall-clock time.
    public static func activeMs(intervals: [Double]) -> Double {
        intervals.filter { $0 <= MetricConstants.idleMs }.reduce(0, +)
    }

    /// Words per minute over all character-producing keystrokes, including ones
    /// later deleted.
    public static func gross(characterKeystrokes: Int, activeMs: Double) -> Double {
        guard activeMs > 0 else { return 0 }
        let words = Double(characterKeystrokes) / MetricConstants.charactersPerWord
        return words / (activeMs / 60_000)
    }

    /// Speed net of corrections, for use where no ground truth exists.
    ///
    /// Each backspace is charged twice: once for the wasted keystroke and once for
    /// the character it removed. This is a heuristic, and the UI must label it
    /// "effective" rather than presenting it as a measurement.
    public static func effective(
        characterKeystrokes: Int,
        backspaces: Int,
        activeMs: Double
    ) -> Double {
        guard activeMs > 0 else { return 0 }
        let net = max(0, Double(characterKeystrokes) - 2 * Double(backspaces))
        return (net / MetricConstants.charactersPerWord) / (activeMs / 60_000)
    }

    /// Speed over correct characters only. Requires ground truth, so this is
    /// available in the typing test and nowhere else.
    public static func net(correctCharacters: Int, activeMs: Double) -> Double {
        guard activeMs > 0 else { return 0 }
        let words = Double(correctCharacters) / MetricConstants.charactersPerWord
        return words / (activeMs / 60_000)
    }

    /// The fastest sustained stretch of typing in the session.
    ///
    /// Slides a window of at least `peakWindowMs` across the stream and returns
    /// the highest speed any such window achieved, so the figure reflects a pace
    /// actually held rather than a momentary spike.
    public static func peakWindow(
        events: [TypingEvent],
        windowMs: Double = MetricConstants.peakWindowMs
    ) -> Double {
        guard events.count > 1 else { return 0 }

        var best = 0.0
        var low = 0
        var elapsed = 0.0
        var characters = 0

        for high in 1..<events.count {
            let event = events[high]
            // Idle gaps are not typing, so a window may not span one.
            if event.intervalMs > MetricConstants.idleMs {
                low = high
                elapsed = 0
                characters = 0
                continue
            }
            elapsed += event.intervalMs
            if event.keyClass.producesCharacter { characters += 1 }

            // Shrink from the left while the window stays at or above the target.
            while low < high, elapsed - events[low + 1].intervalMs >= windowMs {
                low += 1
                elapsed -= events[low].intervalMs
                if events[low].keyClass.producesCharacter { characters -= 1 }
            }

            if elapsed >= windowMs {
                best = max(best, gross(characterKeystrokes: characters, activeMs: elapsed))
            }
        }
        return best
    }
}
