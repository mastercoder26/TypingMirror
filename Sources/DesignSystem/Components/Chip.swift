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
        HStack(spacing: Tk.S.s2) {
            Text(emoji).font(.system(size: 12))
            Text(text)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textPrimary)
        }
        .padding(.horizontal, Tk.S.s3)
        .padding(.vertical, Tk.S.s2)
        .glassEffect(
            tinted ? .regular.tint(Tk.C.accent.opacity(0.22)) : .regular,
            in: Capsule()
        )
    }
}
