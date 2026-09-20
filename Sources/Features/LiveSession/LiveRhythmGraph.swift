import SwiftUI
import TypingMirrorKit

/// Real-time rhythm trace.
///
/// The buffer is mutated by keystrokes without notifying SwiftUI; this view
/// redraws on the display's own schedule and reads whatever is there. A thousand
/// keystrokes a minute therefore cost zero view invalidations.
struct LiveRhythmGraph: View {
    let buffer: RhythmBuffer
    var height: CGFloat = 120

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas(rendersAsynchronously: false) { context, size in
                var context = context
                let buckets = RhythmRenderer.barCount(for: size.width)
                RhythmRenderer.draw(
                    into: &context,
                    size: size,
                    samples: buffer.speedSamples(buckets: buckets)
                )
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
