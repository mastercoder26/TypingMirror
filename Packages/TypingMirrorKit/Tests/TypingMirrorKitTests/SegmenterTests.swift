import Foundation
import Testing
@testable import TypingMirrorKit

@Suite("Session segmentation")
struct SessionSegmenterTests {
    static func feed(
        _ segmenter: inout SessionSegmenter,
        intervals: [Double],
        appName: String = "Xcode",
        category: SessionCategory = .coding
    ) -> [SessionSegmenter.Segment] {
        intervals.compactMap {
            segmenter.accept(
                event: TypingEvent(intervalMs: $0, keyClass: .letter),
                at: Date(),
                appName: appName,
                category: category
            )
        }
    }

    @Test("continuous typing stays one session")
    func continuousTypingIsOneSession() {
        var segmenter = SessionSegmenter()
        let finished = Self.feed(&segmenter, intervals: Array(repeating: 180, count: 400))
        #expect(finished.isEmpty)
        #expect(segmenter.close()?.events.count == 400)
    }

    @Test("a two-minute gap starts a new session")
    func longGapSplits() {
        var segmenter = SessionSegmenter()
        var intervals = Array(repeating: 180.0, count: 100)
        intervals.append(130_000)
        intervals += Array(repeating: 180.0, count: 100)

        let finished = Self.feed(&segmenter, intervals: intervals)

        #expect(finished.count == 1)
        #expect(finished[0].events.count == 100)
        // The keystroke that followed the gap opens the new session, so it holds
        // the remaining hundred plus itself.
        #expect(segmenter.close()?.events.count == 101)
    }

    @Test("a short gap does not split")
    func shortGapDoesNotSplit() {
        var segmenter = SessionSegmenter()
        var intervals = Array(repeating: 180.0, count: 50)
        intervals.append(30_000)
        intervals += Array(repeating: 180.0, count: 50)
        #expect(Self.feed(&segmenter, intervals: intervals).isEmpty)
    }

    @Test("a session is capped so replay stays bounded")
    func longSessionIsCapped() {
        var segmenter = SessionSegmenter()
        // Ten thousand keystrokes five seconds apart runs well past the cap.
        let finished = Self.feed(&segmenter, intervals: Array(repeating: 5_000, count: 700))
        #expect(!finished.isEmpty)
        for segment in finished {
            let elapsed = segment.events.reduce(0) { $0 + $1.intervalMs }
            #expect(elapsed <= SessionSegmenter.maximumSessionMs)
        }
    }

    @Test("the first event of a session carries no preceding interval")
    func firstEventHasNoInterval() {
        var segmenter = SessionSegmenter()
        _ = Self.feed(&segmenter, intervals: [999_999, 180, 180])
        #expect(segmenter.close()?.events.first?.intervalMs == 0)
    }

    @Test("switching apps mid-session marks it mixed rather than splitting")
    func appSwitchDoesNotSplit() {
        // Alt-tabbing to look something up is part of one stretch of work.
        var segmenter = SessionSegmenter()
        _ = Self.feed(&segmenter, intervals: Array(repeating: 180, count: 50),
                      appName: "Xcode", category: .coding)
        let finished = Self.feed(&segmenter, intervals: Array(repeating: 180, count: 50),
                                 appName: "Obsidian", category: .writing)

        #expect(finished.isEmpty)
        #expect(segmenter.close()?.category == .mixed)
    }

    @Test("closing an empty segmenter yields nothing")
    func emptyCloseIsSafe() {
        var segmenter = SessionSegmenter()
        #expect(segmenter.close() == nil)
    }
}

@Suite("App categorisation")
struct AppCategoryTests {
    @Test("known editors map to coding")
    func editorsAreCoding() {
        #expect(AppCategoryRules.category(for: "com.apple.dt.Xcode") == .coding)
        #expect(AppCategoryRules.category(for: "com.microsoft.VSCode") == .coding)
    }

    @Test("unknown apps stay mixed rather than being guessed")
    func unknownIsMixed() {
        #expect(AppCategoryRules.category(for: "com.example.unknown") == .mixed)
        #expect(AppCategoryRules.category(for: nil) == .mixed)
    }
}

@Suite("Ring buffer")
struct RingBufferTests {
    @Test("events survive a push and drain")
    func pushAndDrain() {
        let ring = KeyEventRingBuffer(capacityPowerOfTwo: 4)
        for index in 0..<10 {
            ring.tryPush(RawKeyEvent(timestampTicks: UInt64(index), keyClass: 0, isRepeat: false))
        }
        #expect(ring.drain().count == 10)
        #expect(ring.drain().isEmpty)
    }

    @Test("overflow is counted rather than silently lost")
    func overflowIsCounted() {
        // Sixteen slots, thirty-two pushes: the excess must be visible so the
        // affected session can be flagged instead of quietly wrong.
        let ring = KeyEventRingBuffer(capacityPowerOfTwo: 4)
        for index in 0..<32 {
            ring.tryPush(RawKeyEvent(timestampTicks: UInt64(index), keyClass: 0, isRepeat: false))
        }
        #expect(ring.droppedCount == 16)
        #expect(ring.drain().count == 16)
    }
}

@Suite("Key classification")
struct KeyClassTableTests {
    /// Regression guard: the function-key codes were once written as a range, but
    /// they are neither contiguous nor ascending, so merely building the table
    /// trapped and the app died before its window appeared.
    ///
    /// This covers the pure mapping only. Reading the live keyboard layout needs a
    /// window server connection, which a test process does not have.
    @Test("every key code maps without trapping")
    func everyKeyCodeIsSafe() {
        for keyCode in 0..<UInt16(KeyClassTable.tableSize) {
            _ = KeyClassTable.fixedClass(for: keyCode)
        }
    }

    @Test("layout-independent keys classify correctly")
    func fixedKeysAreCorrect() {
        #expect(KeyClassTable.fixedClass(for: 51) == .backspace)
        #expect(KeyClassTable.fixedClass(for: 49) == .space)
        #expect(KeyClassTable.fixedClass(for: 36) == .returnEnter)
        #expect(KeyClassTable.fixedClass(for: 48) == .tab)
        #expect(KeyClassTable.fixedClass(for: 53) == .escape)
        #expect(KeyClassTable.fixedClass(for: 123) == .navigation)
    }

    @Test("function keys are recognised across the whole range")
    func functionKeysAreRecognised() {
        // F1 is 122 and F20 is 90 — the codes that broke the range.
        for keyCode: UInt16 in [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 90] {
            #expect(KeyClassTable.fixedClass(for: keyCode) == .functionKey)
        }
    }

    @Test("a letter key is left to the layout rather than hard-coded")
    func letterKeysDeferToLayout() {
        #expect(KeyClassTable.fixedClass(for: 0) == nil)
    }

    @Test("a modified keypress is a shortcut, not typing")
    func modifiedKeysAreShortcuts() {
        let table = KeyClassTable(classes: [UInt8](repeating: KeyClass.letter.rawValue, count: 128))
        #expect(table.classify(keyCode: 0, hasCommandOrControl: true) == .shortcut)
        #expect(table.classify(keyCode: 0, hasCommandOrControl: false) == .letter)
    }

    @Test("out-of-range codes are unknown rather than a crash")
    func outOfRangeIsSafe() {
        let table = KeyClassTable(classes: [UInt8](repeating: 0, count: 128))
        #expect(table.classify(keyCode: 9_999, hasCommandOrControl: false) == .unknown)
    }
}
