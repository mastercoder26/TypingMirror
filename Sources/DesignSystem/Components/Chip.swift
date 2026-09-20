import SwiftUI

/// An emoji-tagged personality label ("⚡ Fast bursts").
public struct Chip: View {
    private let emoji: String
    private let text: String
    private let tinted: Bool

    public init(emoji: String, text: String, tinted: Bool = false) {
        self.emoji = emoji
        self.text = text
        self.tinted = tinted
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Text(emoji).font(.system(size: 12))
            Text(text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.primaryText)
        }
        .padding(.horizontal, Theme.Spacing.regular)
        .padding(.vertical, Theme.Spacing.small)
        .glassEffect(
            tinted ? .regular.tint(Theme.Colors.accent.opacity(0.22)) : .regular,
            in: Capsule()
        )
    }
}
