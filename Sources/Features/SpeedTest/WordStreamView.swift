import SwiftUI

/// The prompt, coloured per character against what was actually typed.
///
/// Untyped text recedes, correct text is quiet, and only mistakes carry colour —
/// so the eye is drawn to what needs attention and nowhere else.
struct WordStreamView: View {
    let prompt: [String]
    let typed: [String]
    let activeIndex: Int

    private let visibleWords = 36

    var body: some View {
        let range = windowRange
        return Text(attributed(in: range))
            .font(Tk.F.stream)
            .lineSpacing(Tk.S.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(nil, value: activeIndex)
    }

    /// Scrolls the prompt by whole lines rather than tracking the caret exactly,
    /// which would make the text jitter under the eye while typing.
    private var windowRange: Range<Int> {
        let start = max(0, (activeIndex / 12) * 12 - 12)
        return start..<min(prompt.count, start + visibleWords)
    }

    private func attributed(in range: Range<Int>) -> AttributedString {
        var result = AttributedString()
        for index in range {
            result += word(at: index)
            if index < range.upperBound - 1 {
                var space = AttributedString(" ")
                space.foregroundColor = Tk.C.pending
                result += space
            }
        }
        return result
    }

    private func word(at index: Int) -> AttributedString {
        let expected = Array(prompt[index])
        let actual = index < typed.count ? Array(typed[index]) : []
        let isActive = index == activeIndex
        var result = AttributedString()

        for (position, character) in expected.enumerated() {
            var piece = AttributedString(String(character))
            if position < actual.count {
                piece.foregroundColor = actual[position] == character
                    ? Tk.C.correct
                    : Tk.C.incorrect
            } else {
                piece.foregroundColor = isActive ? Tk.C.textSecondary : Tk.C.pending
            }
            // Mark the caret by lifting the next character out of the recessed
            // pending colour, rather than drawing a separate cursor that would
            // need to be kept in sync with the text layout.
            if isActive && position == actual.count {
                piece.foregroundColor = Tk.C.accent
                piece.underlineStyle = .single
            }
            result += piece
        }

        // Anything typed past the end of the word is surfaced rather than hidden.
        if actual.count > expected.count {
            var overflow = AttributedString(String(actual[expected.count...]))
            overflow.foregroundColor = Tk.C.incorrect
            overflow.strikethroughStyle = .single
            result += overflow
        }
        return result
    }
}
