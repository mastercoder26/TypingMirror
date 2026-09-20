import AppKit

/// Captures keystrokes with accurate timing and correct input-method behaviour.
///
/// This implements `NSTextInputClient` directly rather than wrapping `NSTextView`
/// or relying on SwiftUI's `onKeyPress`. `NSTextView` drags in a whole text system
/// we would spend longer suppressing than using, and `KeyPress` carries no event
/// timestamp — timing from it would measure our own dispatch delay. Going through
/// the input system is also what makes dead keys and IME composition behave.
final class KeystrokeNSView: NSView, @MainActor NSTextInputClient {
    var onKeystroke: ((Keystroke) -> Void)?

    /// Stashed in `keyDown` so `insertText` — which AppKit calls without the
    /// originating event — can still report an accurate time.
    private var currentTimestamp: TimeInterval = 0
    private var currentIsRepeat = false
    /// Text being composed by an input method, not yet committed.
    private var markedText = ""

    /// Set by the representable; when true the view claims focus as soon as it
    /// can, including on every move into a window.
    var wantsFocus = false

    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool { true }

    /// Claiming focus in `updateNSView` alone is not enough: the view is not yet
    /// in a window the first time SwiftUI configures it, and the split view's
    /// sidebar list otherwise keeps first responder. Without this, keystrokes go
    /// to the sidebar and type-select its rows instead of reaching the test.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        claimFocusIfWanted()
    }

    func claimFocusIfWanted() {
        guard wantsFocus, let window, window.firstResponder !== self else { return }
        // Deferred by one turn of the run loop so it wins against SwiftUI
        // restoring focus to the sidebar after navigation.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.wantsFocus, let window = self.window else { return }
            window.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        currentTimestamp = event.timestamp
        currentIsRepeat = event.isARepeat
        // Routing through the input system means a dead key such as ⌥e followed by
        // a vowel arrives as one composed character, which is the semantically
        // correct answer for a rhythm measurement.
        interpretKeyEvents([event])
    }

    // MARK: NSTextInputClient

    func insertText(_ string: Any, replacementRange: NSRange) {
        let text = (string as? String)
            ?? (string as? NSAttributedString)?.string
            ?? ""
        markedText = ""
        for character in text {
            onKeystroke?(
                Keystroke(kind: .text(character), timestamp: currentTimestamp, isRepeat: currentIsRepeat)
            )
        }
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        // A composition in progress is not yet a typed character, so nothing is
        // emitted until it commits through `insertText`.
        markedText = (string as? String)
            ?? (string as? NSAttributedString)?.string
            ?? ""
    }

    func unmarkText() { markedText = "" }
    func hasMarkedText() -> Bool { !markedText.isEmpty }

    override func doCommand(by selector: Selector) {
        let kind: Keystroke.Kind?
        switch selector {
        case #selector(NSResponder.deleteBackward(_:)): kind = .backspace
        case #selector(NSResponder.deleteWordBackward(_:)): kind = .wordDelete
        default: kind = nil
        }
        guard let kind else { return }
        onKeystroke?(Keystroke(kind: kind, timestamp: currentTimestamp, isRepeat: currentIsRepeat))
    }

    func selectedRange() -> NSRange { NSRange(location: NSNotFound, length: 0) }
    func markedRange() -> NSRange { NSRange(location: NSNotFound, length: 0) }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? { nil }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }
    func characterIndex(for point: NSPoint) -> Int { 0 }

    /// Positions the input method's candidate window under the caret.
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        guard let window else { return .zero }
        return window.convertToScreen(convert(bounds, to: nil))
    }
}
