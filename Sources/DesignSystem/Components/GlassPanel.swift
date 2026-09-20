import SwiftUI

/// The workhorse content card.
///
/// Glass alone on a near-black backdrop reads as a smudge, so every panel also
/// carries a hairline stroke to define its edge.
public struct GlassPanel<Content: View>: View {
    public enum Emphasis {
        case standard, quiet, hero
    }

    private let emphasis: Emphasis
    private let radius: CGFloat
    private let content: Content

    public init(
        emphasis: Emphasis = .standard,
        radius: CGFloat = Tk.R.md,
        @ViewBuilder content: () -> Content
    ) {
        self.emphasis = emphasis
        self.radius = radius
        self.content = content()
    }

    private var glass: Glass {
        switch emphasis {
        case .standard: .regular
        case .quiet: .clear
        case .hero: .regular.tint(Tk.C.accent.opacity(0.18))
        }
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(.horizontal, Tk.S.s4)
            .padding(.vertical, Tk.S.s3)
            .glassEffect(glass, in: shape)
            .overlay(shape.strokeBorder(Tk.C.strokeSoft, lineWidth: 1))
            .shadow(
                color: .black.opacity(Tk.Z.liftOpacity),
                radius: Tk.Z.liftRadius,
                y: Tk.Z.liftY
            )
    }
}
