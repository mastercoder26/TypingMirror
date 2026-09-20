import SwiftUI

/// Draws a rhythm trace into a `GraphicsContext`.
///
/// Shared by the session detail bar, the live graph, and the replay scrubber, so
/// that the same session looks the same wherever it appears.
public enum RhythmRenderer {
    public struct Style {
        public var barWidth: CGFloat = 3
        public var gap: CGFloat = 3
        public var minimumHeightFraction: Double = 0.06
        public var cornerRadius: CGFloat = 1.5

        public init() {}
    }

    /// Number of bars that fit the given width.
    public static func barCount(for width: CGFloat, style: Style = Style()) -> Int {
        max(1, Int((width + style.gap) / (style.barWidth + style.gap)))
    }

    /// `samples` are normalised 0...1, where 1 is this typist's fastest.
    public static func draw(
        into context: inout GraphicsContext,
        size: CGSize,
        samples: [Double],
        style: Style = Style(),
        highlightIndex: Int? = nil
    ) {
        guard !samples.isEmpty, size.width > 0 else { return }

        let count = samples.count
        let slot = size.width / CGFloat(count)
        let barWidth = max(1, slot - style.gap)

        for (index, sample) in samples.enumerated() {
            let fraction = max(style.minimumHeightFraction, min(1, sample))
            let height = size.height * fraction
            let rect = CGRect(
                x: CGFloat(index) * slot,
                y: size.height - height,
                width: barWidth,
                height: height
            )
            // Brightness encodes speed, so the trace reads without any colour.
            let shade = highlightIndex == index
                ? Tk.C.textPrimary
                : Tk.C.viz(0.25 + fraction * 0.75)
            context.fill(
                Path(roundedRect: rect, cornerRadius: style.cornerRadius),
                with: .color(shade)
            )
        }
    }
}
