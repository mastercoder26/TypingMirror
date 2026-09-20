import SwiftUI

/// A content panel with a thin border to keep its edge visible on the backdrop.
public struct GlassPanel<Content: View>: View {
    public enum Emphasis {
        case standard, quiet, hero
    }

    private let emphasis: Emphasis
    private let radius: CGFloat
    private let content: Content

    public init(
        emphasis: Emphasis = .standard,
        radius: CGFloat = Theme.Radius.medium,
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
        case .hero: .regular.tint(Theme.Colors.accent.opacity(0.18))
        }
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.regular)
            .glassEffect(glass, in: shape)
            .overlay(shape.strokeBorder(Theme.Colors.subtleBorder, lineWidth: 1))
            .shadow(
                color: .black.opacity(Theme.Shadows.liftOpacity),
                radius: Theme.Shadows.liftRadius,
                y: Theme.Shadows.liftY
            )
    }
}
