import SwiftUI

/// Colors the prompt against the typed characters and marks the next character.
struct WordStreamView: View {
    let prompt: [String]
    let typed: [String]
    let activeIndex: Int

    private let visibleWords = 36

    var body: some View {
        let range = windowRange
        return Text(attributed(in: range))
            .font(Theme.Typography.stream)
            .lineSpacing(Theme.Spacing.regular)
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
                space.foregroundColor = Theme.Colors.pending
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
                    ? Theme.Colors.correct
                    : Theme.Colors.incorrect
            } else {
                piece.foregroundColor = isActive ? Theme.Colors.secondaryText : Theme.Colors.pending
            }
            // Underlining the next character keeps the caret in the text layout.
            if isActive && position == actual.count {
                piece.foregroundColor = Theme.Colors.accent
                piece.underlineStyle = .single
            }
            result += piece
        }

        // Anything typed past the end of the word is surfaced rather than hidden.
        if actual.count > expected.count {
            var overflow = AttributedString(String(actual[expected.count...]))
            overflow.foregroundColor = Theme.Colors.incorrect
            overflow.strikethroughStyle = .single
            result += overflow
        }
        return result
    }
}
