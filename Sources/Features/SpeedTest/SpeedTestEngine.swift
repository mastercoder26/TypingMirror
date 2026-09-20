import Foundation
import Observation
import TypingMirrorKit

/// Drives one typing test.
///
/// Live figures are published on a timer rather than per keystroke, so that the
/// header does not invalidate the view hierarchy at typing speed.
@MainActor
@Observable
final class SpeedTestEngine {
    enum Phase: Equatable {
        case idle, running, finished
    }

    private(set) var phase: Phase = .idle
    private(set) var prompt: [String] = []
    private(set) var typedWords: [String] = []
    private(set) var currentWord = ""
    private(set) var wordIndex = 0

    private(set) var liveWPM = 0.0
    private(set) var liveAccuracy = 1.0
    private(set) var elapsedMs = 0.0
    private(set) var score: TestScore?

    /// Not observed — see `RhythmBuffer`.
    let rhythm = RhythmBuffer()

    private var events: [TypingEvent] = []
    private var estimator = LiveRhythmEstimator()
    private var firstTimestamp: TimeInterval?
    private var lastTimestamp: TimeInterval?
    private var correctKeystrokes = 0
    private var totalKeystrokes = 0
    private var tickTask: Task<Void, Never>?
    /// Lead-in delay before each word, used for the hesitation list.
    private var wordLeadInMs = 0.0
    private var pendingHesitations: [(word: String, hesitationMs: Double)] = []

    let wordCount: Int

    init(wordCount: Int = 60) {
        self.wordCount = wordCount
        reset()
    }

    var typedSoFar: [String] {
        typedWords + [currentWord]
    }

    func reset(seed: UInt64 = UInt64.random(in: 0..<UInt64.max)) {
        tickTask?.cancel()
        tickTask = nil
        phase = .idle
        prompt = WordList.prompt(count: wordCount, seed: seed)
        typedWords = []
        currentWord = ""
        wordIndex = 0
        liveWPM = 0
        liveAccuracy = 1
        elapsedMs = 0
        score = nil
        events = []
        estimator = LiveRhythmEstimator()
        firstTimestamp = nil
        lastTimestamp = nil
        correctKeystrokes = 0
        totalKeystrokes = 0
        wordLeadInMs = 0
        pendingHesitations = []
        rhythm.reset()
    }

    func handle(_ keystroke: Keystroke) {
        guard phase != .finished else { return }
        // Held keys are motor repeat, not typing, and would distort the rhythm.
        guard !keystroke.isRepeat else { return }

        if phase == .idle {
            phase = .running
            startedAt = Date()
            firstTimestamp = keystroke.timestamp
            startTicking()
        }

        let ms = (keystroke.timestamp - (firstTimestamp ?? keystroke.timestamp)) * 1000
        let interval = lastTimestamp.map { (keystroke.timestamp - $0) * 1000 } ?? 0
        lastTimestamp = keystroke.timestamp
        rhythm.record(atMs: keystroke.timestamp * 1000)
        estimator.ingest(atMs: ms)

        switch keystroke.kind {
        case .text(let character) where character == " ":
            commitWord(leadInMs: wordLeadInMs)
            events.append(TypingEvent(intervalMs: interval, keyClass: .space))
        case .text(let character):
            append(character, interval: interval)
        case .backspace:
            if !currentWord.isEmpty { currentWord.removeLast() }
            events.append(TypingEvent(intervalMs: interval, keyClass: .backspace))
        case .wordDelete:
            currentWord = ""
            events.append(TypingEvent(intervalMs: interval, keyClass: .backspace))
        }

        elapsedMs = ms
        if wordIndex >= prompt.count { finish() }
    }

    private func append(_ character: Character, interval: Double) {
        let position = currentWord.count
        // The gap before a word's first character is the hesitation on that word.
        if position == 0 { wordLeadInMs = interval }
        let expected = Array(prompt[min(wordIndex, prompt.count - 1)])
        totalKeystrokes += 1
        if position < expected.count, expected[position] == character {
            correctKeystrokes += 1
        }
        currentWord.append(character)
        events.append(
            TypingEvent(
                intervalMs: interval,
                keyClass: character.isLetter ? .letter : .punctuation,
                wordPosition: UInt8(min(position, 255))
            )
        )
    }

    private func commitWord(leadInMs: Double = 0) {
        guard !currentWord.isEmpty else { return }
        // Only genuinely long lead-ins are worth reporting, and only when the word
        // was typed correctly — otherwise the delay is confusion, not hesitation.
        if leadInMs > MetricConstants.pauseMs,
           wordIndex < prompt.count,
           prompt[wordIndex] == currentWord {
            pendingHesitations.append((word: currentWord, hesitationMs: leadInMs))
        }
        typedWords.append(currentWord)
        currentWord = ""
        wordIndex += 1
        totalKeystrokes += 1
        correctKeystrokes += 1
    }

    /// The recorded stream, for persistence once the test ends.
    var recordedEvents: [TypingEvent] { events }
    var hesitations: [(word: String, hesitationMs: Double)] { pendingHesitations }
    private(set) var startedAt = Date()

    func finish() {
        guard phase == .running else { return }
        if !currentWord.isEmpty { commitWord(leadInMs: wordLeadInMs) }
        phase = .finished
        tickTask?.cancel()
        tickTask = nil

        let activeMs = WPMCalculator.activeMs(intervals: events.dropFirst().map(\.intervalMs))
        score = TypingTestScorer.score(
            prompt: prompt,
            typed: typedWords,
            activeMs: activeMs,
            correctKeystrokes: correctKeystrokes,
            totalKeystrokes: totalKeystrokes
        )
    }

    /// Republishes live figures ten times a second. Fast enough to feel immediate,
    /// slow enough that the view hierarchy is not rebuilt per keystroke.
    private func startTicking() {
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.phase == .running else { return }
                self.publishLiveFigures()
            }
        }
    }

    private func publishLiveFigures() {
        liveWPM = estimator.instantaneousWPM(atMs: elapsedMs + 100)
        liveAccuracy = totalKeystrokes > 0
            ? Double(correctKeystrokes) / Double(totalKeystrokes)
            : 1
    }
}
