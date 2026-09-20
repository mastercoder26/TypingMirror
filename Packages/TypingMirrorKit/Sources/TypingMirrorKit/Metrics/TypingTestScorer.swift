import Foundation

/// Result of scoring a finished typing test.
public struct TestScore: Sendable, Equatable {
    public let correctCharacters: Int
    public let incorrectCharacters: Int
    public let extraCharacters: Int
    public let missedCharacters: Int
    public let netWPM: Double
    /// Share of the final text that ended up right.
    public let accuracy: Double
    /// Share of keystrokes that were right *at the moment they were typed*.
    ///
    /// This differs from `accuracy` and the two tell different stories: how often
    /// you erred, versus how much you failed to fix.
    public let rawAccuracy: Double
}

/// Word-by-word scoring, matching what the typist watched happen on screen.
///
/// Alignment is positional rather than edit-distance based. Levenshtein can
/// realign across a skipped word and award credit that contradicts what was
/// visibly typed, which makes the score feel wrong even when it is defensible.
public enum TypingTestScorer {
    public static func score(
        prompt: [String],
        typed: [String],
        activeMs: Double,
        correctKeystrokes: Int,
        totalKeystrokes: Int
    ) -> TestScore {
        var correct = 0
        var incorrect = 0
        var extra = 0
        var missed = 0

        for index in 0..<typed.count {
            let typedWord = Array(typed[index])
            guard index < prompt.count else {
                extra += typedWord.count
                continue
            }
            let promptWord = Array(prompt[index])
            let shared = min(promptWord.count, typedWord.count)

            for position in 0..<shared {
                if promptWord[position] == typedWord[position] {
                    correct += 1
                } else {
                    incorrect += 1
                }
            }
            extra += max(0, typedWord.count - promptWord.count)
            missed += max(0, promptWord.count - typedWord.count)

            // The delimiting space counts as a correct character only when the
            // whole word matched, so a near-miss never scores as clean.
            let isLastTyped = index == typed.count - 1
            if !isLastTyped && promptWord == typedWord { correct += 1 }
        }

        let graded = correct + incorrect + extra + missed
        return TestScore(
            correctCharacters: correct,
            incorrectCharacters: incorrect,
            extraCharacters: extra,
            missedCharacters: missed,
            netWPM: WPMCalculator.net(correctCharacters: correct, activeMs: activeMs),
            accuracy: graded > 0 ? Double(correct) / Double(graded) : 0,
            rawAccuracy: totalKeystrokes > 0
                ? Double(correctKeystrokes) / Double(totalKeystrokes)
                : 0
        )
    }
}
